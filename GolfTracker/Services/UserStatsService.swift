import Foundation
import Supabase

// MARK: - User Stats Service

@MainActor
class UserStatsService {
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
    
    // MARK: - User Statistics
    
    func fetchUserStats(userId: String) async throws -> UserGolfStats? {
        let response: [UserStatsResponse] = try await supabase
            .from("user_golf_stats")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        guard let statsResponse = response.first else { return nil }
        
        return convertToUserGolfStats(statsResponse)
    }
    
    private func convertToUserGolfStats(_ statsResponse: UserStatsResponse) -> UserGolfStats {
        let dateFormatters = createDateFormatters()
        
        let lastPlayedDate: Date?
        if let dateString = statsResponse.lastPlayedDate {
            lastPlayedDate = dateFormatters.simple.date(from: dateString) ?? 
                           dateFormatters.iso8601.date(from: dateString)
        } else {
            lastPlayedDate = nil
        }
        
        let updatedAt = dateFormatters.iso8601.date(from: statsResponse.updatedAt) ?? Date()
        
        return UserGolfStats(
            userId: statsResponse.userId,
            totalRounds: statsResponse.totalRounds,
            averageScore: statsResponse.averageScore,
            bestScore: statsResponse.bestScore,
            worstScore: statsResponse.worstScore,
            handicapIndex: statsResponse.handicapIndex,
            totalBirdies: statsResponse.totalBirdies,
            totalEagles: statsResponse.totalEagles,
            totalPars: statsResponse.totalPars,
            totalBogeys: statsResponse.totalBogeys,
            favoriteCourse: statsResponse.favoriteCourse,
            lastPlayedDate: lastPlayedDate,
            updatedAt: updatedAt
        )
    }
    
    private func createDateFormatters() -> (iso8601: ISO8601DateFormatter, simple: DateFormatter) {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        simpleDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return (iso8601Formatter, simpleDateFormatter)
    }
    
    // MARK: - Response Models
    
    struct UserStatsResponse: Codable {
        let userId: String
        let totalRounds: Int
        let averageScore: Double?
        let bestScore: Int?
        let worstScore: Int?
        let handicapIndex: Double?
        let totalBirdies: Int
        let totalEagles: Int
        let totalPars: Int
        let totalBogeys: Int
        let favoriteCourse: String?
        let lastPlayedDate: String?
        let updatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case totalRounds = "total_rounds"
            case averageScore = "average_score"
            case bestScore = "best_score"
            case worstScore = "worst_score"
            case handicapIndex = "handicap_index"
            case totalBirdies = "total_birdies"
            case totalEagles = "total_eagles"
            case totalPars = "total_pars"
            case totalBogeys = "total_bogeys"
            case favoriteCourse = "favorite_course"
            case lastPlayedDate = "last_played_date"
            case updatedAt = "updated_at"
        }
    }
    
    func updateUserStats(userId: String, rounds: [GolfRound]) async throws {
        guard !rounds.isEmpty else {
            try await createEmptyStats(userId: userId)
            return
        }
        
        let basicStats = calculateBasicStats(from: rounds)
        let holeStats = try await calculateHoleScoreStatistics(userId: userId)
        let statsUpsert = createUserStatsUpsert(
            userId: userId,
            basicStats: basicStats,
            holeStats: holeStats
        )
        
        try await supabase
            .from("user_golf_stats")
            .upsert(statsUpsert)
            .execute()
    }
    
    func updateUserHandicap(userId: String, handicap: Double?) async throws {
        struct HandicapUpdate: Encodable {
            let userId: String
            let handicapIndex: Double?
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case handicapIndex = "handicap_index"
                case updatedAt = "updated_at"
            }
        }
        
        let handicapData = HandicapUpdate(
            userId: userId,
            handicapIndex: handicap,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("user_golf_stats")
            .upsert(handicapData)
            .execute()
    }
    
    // MARK: - Private Helper Functions
    
    private func createEmptyStats(userId: String) async throws {
        struct EmptyStatsUpsert: Encodable {
            let userId: String
            let totalRounds: Int
            let averageScore: Double?
            let bestScore: Int?
            let worstScore: Int?
            let handicapIndex: Double?
            let totalBirdies: Int
            let totalEagles: Int
            let totalPars: Int
            let totalBogeys: Int
            let favoriteCourse: String?
            let lastPlayedDate: String?
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case totalRounds = "total_rounds"
                case averageScore = "average_score"
                case bestScore = "best_score"
                case worstScore = "worst_score"
                case handicapIndex = "handicap_index"
                case totalBirdies = "total_birdies"
                case totalEagles = "total_eagles"
                case totalPars = "total_pars"
                case totalBogeys = "total_bogeys"
                case favoriteCourse = "favorite_course"
                case lastPlayedDate = "last_played_date"
                case updatedAt = "updated_at"
            }
        }
        
        let emptyStats = EmptyStatsUpsert(
            userId: userId,
            totalRounds: 0,
            averageScore: nil,
            bestScore: nil,
            worstScore: nil,
            handicapIndex: nil,
            totalBirdies: 0,
            totalEagles: 0,
            totalPars: 0,
            totalBogeys: 0,
            favoriteCourse: nil,
            lastPlayedDate: nil,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("user_golf_stats")
            .upsert(emptyStats)
            .execute()
    }
    
    private func calculateBasicStats(from rounds: [GolfRound]) -> BasicGolfStats {
        let totalRounds = rounds.count
        let scores = rounds.map { $0.totalScore }
        let averageScore = Double(scores.reduce(0, +)) / Double(totalRounds)
        let bestScore = scores.min()
        let worstScore = scores.max()
        let lastPlayedDate = rounds.map { $0.date }.max()
        
        // Find favorite course (most played)
        let courseCounts = Dictionary(grouping: rounds, by: { $0.courseName })
        let favoriteCourse = courseCounts.max(by: { $0.value.count < $1.value.count })?.key
        
        // Calculate handicap (simplified - using average score vs par)
        let totalPar = rounds.map { $0.par }.reduce(0, +)
        let totalScore = scores.reduce(0, +)
        let handicapIndex = totalRounds > 5 ? Double(totalScore - totalPar) / Double(totalRounds) : nil
        
        return BasicGolfStats(
            totalRounds: totalRounds,
            averageScore: averageScore,
            bestScore: bestScore,
            worstScore: worstScore,
            handicapIndex: handicapIndex,
            favoriteCourse: favoriteCourse,
            lastPlayedDate: lastPlayedDate
        )
    }
    
    private func createUserStatsUpsert(
        userId: String,
        basicStats: BasicGolfStats,
        holeStats: HoleScoreStatistics
    ) -> UserStatsUpsert {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return UserStatsUpsert(
            userId: userId,
            totalRounds: basicStats.totalRounds,
            averageScore: basicStats.averageScore,
            bestScore: basicStats.bestScore,
            worstScore: basicStats.worstScore,
            handicapIndex: basicStats.handicapIndex,
            totalBirdies: holeStats.birdies,
            totalEagles: holeStats.eagles,
            totalPars: holeStats.pars,
            totalBogeys: holeStats.bogeys,
            favoriteCourse: basicStats.favoriteCourse,
            lastPlayedDate: basicStats.lastPlayedDate.map { dateFormatter.string(from: $0) },
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    private func calculateHoleScoreStatistics(userId: String) async throws -> HoleScoreStatistics {
        struct HoleScoreResponse: Codable {
            let holeNumber: Int
            let par: Int
            let strokes: Int
            
            enum CodingKeys: String, CodingKey {
                case holeNumber = "hole_number"
                case par
                case strokes
            }
        }
        
        let holeScores: [HoleScoreResponse] = try await supabase
            .from("hole_scores")
            .select("hole_number, par, strokes")
            .in("round_id", values: try await fetchAllRoundIds(userId: userId))
            .execute()
            .value
        
        var birdies = 0
        var eagles = 0
        var pars = 0
        var bogeys = 0
        
        for score in holeScores {
            let difference = score.strokes - score.par
            
            switch difference {
            case ...(-2):
                eagles += 1
            case -1:
                birdies += 1
            case 0:
                pars += 1
            case 1...:
                bogeys += 1
            default:
                break
            }
        }
        
        return HoleScoreStatistics(birdies: birdies, eagles: eagles, pars: pars, bogeys: bogeys)
    }
    
    private func fetchAllRoundIds(userId: String) async throws -> [String] {
        struct RoundIdResponse: Codable {
            let id: String
        }
        
        let response: [RoundIdResponse] = try await supabase
            .from("golf_rounds")
            .select("id")
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response.map { $0.id }
    }
}
