import Foundation
import Supabase

// MARK: - Golf Rounds Service

@MainActor
class GolfRoundsService {
    private let supabase: SupabaseClient
    
    init() {
        guard let supabaseURL = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL configuration")
        }
        let supabaseKey = SupabaseConfig.supabaseAnonKey
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
    
    // MARK: - Golf Rounds
    
    func fetchRecentRounds(userId: String, limit: Int = 10) async throws -> [GolfRound] {
        let response: [RoundResponse] = try await supabase
            .from("golf_rounds")
            .select("""
                id, user_id, course_name, date, total_score, par, notes, 
                created_at, updated_at
            """)
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        // Set up date formatters
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        simpleDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Convert response to GolfRound objects
        return response.map { responseRound in
            // Try different date formats
            let date = iso8601Formatter.date(from: responseRound.date) ?? 
                       simpleDateFormatter.date(from: responseRound.date) ?? 
                       Date()
            
            let createdAt = iso8601Formatter.date(from: responseRound.createdAt) ?? Date()
            let updatedAt = iso8601Formatter.date(from: responseRound.updatedAt) ?? Date()
            
            return GolfRound(
                id: responseRound.id,
                userId: responseRound.userId,
                courseName: responseRound.courseName,
                date: date,
                totalScore: responseRound.totalScore,
                par: responseRound.par,
                holes: [], // Empty for now
                notes: responseRound.notes,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
    
    func fetchAllRounds(userId: String) async throws -> [GolfRound] {
        return try await fetchRecentRounds(userId: userId, limit: 1000)
    }
    
    // MARK: - Create New Round
    
    func createRound(_ request: CreateRoundRequest, userId: String) async throws -> GolfRound {
        let responseRound = try await insertRoundData(request: request, userId: userId)
        let createdRound = createGolfRoundFromResponse(responseRound, originalRequest: request)
        try await insertHoleScores(request.holes, roundId: createdRound.id)
        
        return createdRound
    }
    
    // MARK: - Private Helper Functions
    
    private func insertRoundData(request: CreateRoundRequest, userId: String) async throws -> RoundResponse {
        struct RoundInsert: Encodable {
            let userId: String
            let courseName: String
            let date: String
            let totalScore: Int
            let par: Int
            let notes: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case courseName = "course_name"
                case date
                case totalScore = "total_score"
                case par
                case notes
            }
        }
        
        let roundData = RoundInsert(
            userId: userId,
            courseName: request.courseName,
            date: ISO8601DateFormatter().string(from: request.date),
            totalScore: request.totalScore,
            par: request.par,
            notes: request.notes ?? ""
        )
        
        let roundResponse: [RoundResponse] = try await supabase
            .from("golf_rounds")
            .insert(roundData)
            .select()
            .execute()
            .value
        
        guard let responseRound = roundResponse.first else {
            throw NSError(domain: "GolfRoundsService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create round"])
        }
        
        return responseRound
    }
    
    private func createGolfRoundFromResponse(_ response: RoundResponse, originalRequest: CreateRoundRequest) -> GolfRound {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return GolfRound(
            id: response.id,
            userId: response.userId,
            courseName: response.courseName,
            date: iso8601Formatter.date(from: response.date) ?? originalRequest.date,
            totalScore: response.totalScore,
            par: response.par,
            holes: [], // Will be populated from hole scores
            notes: response.notes.isEmpty ? nil : response.notes,
            createdAt: iso8601Formatter.date(from: response.createdAt) ?? Date(),
            updatedAt: iso8601Formatter.date(from: response.updatedAt) ?? Date()
        )
    }
    
    private func insertHoleScores(_ holes: [CreateHoleScoreRequest], roundId: String) async throws {
        struct HoleScoreInsert: Encodable {
            let roundId: String
            let holeNumber: Int
            let par: Int
            let strokes: Int
            let putts: Int?
            let fairwayHit: Bool?
            let greenInRegulation: Bool?
            
            enum CodingKeys: String, CodingKey {
                case roundId = "round_id"
                case holeNumber = "hole_number"
                case par
                case strokes
                case putts
                case fairwayHit = "fairway_hit"
                case greenInRegulation = "green_in_regulation"
            }
        }
        
        for holeRequest in holes {
            let holeData = HoleScoreInsert(
                roundId: roundId,
                holeNumber: holeRequest.holeNumber,
                par: holeRequest.par,
                strokes: holeRequest.strokes,
                putts: holeRequest.putts,
                fairwayHit: holeRequest.fairwayHit,
                greenInRegulation: holeRequest.greenInRegulation
            )
            
            try await supabase
                .from("hole_scores")
                .insert(holeData)
                .execute()
        }
    }
}
