//
//  SupabaseDataService.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation
import Supabase

@MainActor
class SupabaseDataService: ObservableObject {
    @Published var dashboardData = DashboardData(isLoading: true)
    
    private let supabase: SupabaseClient
    private let authService: SupabaseAuthService
    
    init(authService: SupabaseAuthService) {
        self.authService = authService
        
        // Use same configuration as auth service
        guard let supabaseURL = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL configuration")
        }
        let supabaseKey = SupabaseConfig.supabaseAnonKey
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        // Listen for auth changes
        Task {
            await observeAuthChanges()
        }
    }
    
    // MARK: - Auth Observation
    
    private func observeAuthChanges() async {
        // When user logs in, fetch their data
        if authService.session != nil {
            await fetchDashboardData()
        } else {
            // Clear data when user logs out
            dashboardData = DashboardData()
        }
    }
    
    // MARK: - Dashboard Data
    
    func fetchDashboardData() async {
        guard let userId = authService.session?.user.id else {
            dashboardData = DashboardData(errorMessage: "User not authenticated")
            return
        }
        
        dashboardData = DashboardData(isLoading: true)
        
        do {
            // Fetch user stats and recent rounds in parallel
            async let userStats = fetchUserStats(userId: userId)
            async let recentRounds = fetchRecentRounds(userId: userId, limit: 5)
            
            let stats = try await userStats
            let rounds = try await recentRounds
            
            dashboardData = DashboardData(
                userStats: stats,
                recentRounds: rounds,
                isLoading: false
            )
        } catch {
            dashboardData = DashboardData(
                isLoading: false,
                errorMessage: "Failed to load data: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - User Statistics
    
    private func fetchUserStats(userId: String) async throws -> UserGolfStats? {
        // Create response structure that matches Supabase format
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
        
        let response: [UserStatsResponse] = try await supabase
            .from("user_golf_stats")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        guard let statsResponse = response.first else { return nil }
        
        // Set up date formatters
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        simpleDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Convert response to UserGolfStats
        let lastPlayedDate: Date?
        if let dateString = statsResponse.lastPlayedDate {
            lastPlayedDate = simpleDateFormatter.date(from: dateString) ?? 
                           iso8601Formatter.date(from: dateString)
        } else {
            lastPlayedDate = nil
        }
        
        let updatedAt = iso8601Formatter.date(from: statsResponse.updatedAt) ?? Date()
        
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
    
    func updateUserStats(userId: String) async throws {
        // This function recalculates and updates user statistics
        // It's called after adding/updating rounds
        
        // Use the same method we created for fetching rounds
        let rounds = try await fetchAllRounds(userId: userId)
        
        guard !rounds.isEmpty else {
            // No rounds yet, create empty stats
            struct EmptyStatsUpsert: Encodable {
                let user_id: String
                let total_rounds: Int
                let average_score: Double?
                let best_score: Int?
                let worst_score: Int?
                let handicap_index: Double?
                let total_birdies: Int
                let total_eagles: Int
                let total_pars: Int
                let total_bogeys: Int
                let favorite_course: String?
                let last_played_date: String?
                let updated_at: String
            }
            
            let emptyStats = EmptyStatsUpsert(
                user_id: userId,
                total_rounds: 0,
                average_score: nil,
                best_score: nil,
                worst_score: nil,
                handicap_index: nil,
                total_birdies: 0,
                total_eagles: 0,
                total_pars: 0,
                total_bogeys: 0,
                favorite_course: nil,
                last_played_date: nil,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("user_golf_stats")
                .upsert(emptyStats)
                .execute()
            return
        }
        
        // Calculate statistics
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
        
        // Calculate hole score statistics
        let (totalBirdies, totalEagles, totalPars, totalBogeys) = try await calculateHoleScoreStatistics(userId: userId)
        
        // Create encodable stats structure for upsert
        struct UserStatsUpsert: Encodable {
            let user_id: String
            let total_rounds: Int
            let average_score: Double?
            let best_score: Int?
            let worst_score: Int?
            let handicap_index: Double?
            let total_birdies: Int
            let total_eagles: Int
            let total_pars: Int
            let total_bogeys: Int
            let favorite_course: String?
            let last_played_date: String?
            let updated_at: String
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let updatedStats = UserStatsUpsert(
            user_id: userId,
            total_rounds: totalRounds,
            average_score: averageScore,
            best_score: bestScore,
            worst_score: worstScore,
            handicap_index: handicapIndex,
            total_birdies: totalBirdies,
            total_eagles: totalEagles,
            total_pars: totalPars,
            total_bogeys: totalBogeys
            favorite_course: favoriteCourse,
            last_played_date: lastPlayedDate.map { dateFormatter.string(from: $0) },
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("user_golf_stats")
            .upsert(updatedStats)
            .execute()
    }
    
    // MARK: - Golf Rounds
    
    func fetchRecentRounds(userId: String, limit: Int = 10) async throws -> [GolfRound] {
        // Create response structure that matches Supabase format
        struct RoundResponse: Codable {
            let id: String
            let userId: String
            let courseName: String
            let date: String
            let totalScore: Int
            let par: Int
            let notes: String?
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case courseName = "course_name"
                case date
                case totalScore = "total_score"
                case par
                case notes
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
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
    
    func createRound(_ request: CreateRoundRequest) async throws -> GolfRound {
        guard let userId = authService.session?.user.id else {
            throw NSError(domain: "SupabaseDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Create encodable round data structure
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
        
        // Create a response structure that matches what Supabase returns
        struct RoundResponse: Codable {
            let id: String
            let user_id: String
            let course_name: String
            let date: String
            let total_score: Int
            let par: Int
            let notes: String
            let created_at: String
            let updated_at: String
        }
        
        let roundResponse: [RoundResponse] = try await supabase
            .from("golf_rounds")
            .insert(roundData)
            .select()
            .execute()
            .value
        
        guard let responseRound = roundResponse.first else {
            throw NSError(domain: "SupabaseDataService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create round"])
        }
        
        // Convert response to GolfRound
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdRound = GolfRound(
            id: responseRound.id,
            userId: responseRound.user_id,
            courseName: responseRound.course_name,
            date: iso8601Formatter.date(from: responseRound.date) ?? request.date,
            totalScore: responseRound.total_score,
            par: responseRound.par,
            holes: [], // Will be populated from hole scores
            notes: responseRound.notes.isEmpty ? nil : responseRound.notes,
            createdAt: iso8601Formatter.date(from: responseRound.created_at) ?? Date(),
            updatedAt: iso8601Formatter.date(from: responseRound.updated_at) ?? Date()
        )
        
        // Create encodable hole score data structure
        struct HoleScoreInsert: Encodable {
            let round_id: String
            let hole_number: Int
            let par: Int
            let strokes: Int
            let putts: Int?
            let fairway_hit: Bool?
            let green_in_regulation: Bool?
        }
        
        // Create hole scores
        for holeRequest in request.holes {
            let holeData = HoleScoreInsert(
                round_id: createdRound.id,
                hole_number: holeRequest.holeNumber,
                par: holeRequest.par,
                strokes: holeRequest.strokes,
                putts: holeRequest.putts,
                fairway_hit: holeRequest.fairwayHit,
                green_in_regulation: holeRequest.greenInRegulation
            )
            
            try await supabase
                .from("hole_scores")
                .insert(holeData)
                .execute()
        }
        
        // Update user statistics
        try await updateUserStats(userId: userId)
        
        // Refresh dashboard data
        await fetchDashboardData()
        
        return createdRound
    }
    
    // MARK: - Profile Updates
    
    func updateUserName(newName: String) async throws {
        guard let userId = authService.session?.user.id else {
            throw NSError(domain: "SupabaseDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Update user metadata in Supabase Auth using proper UserAttributes
        try await supabase.auth.update(
            user: .init(data: ["name": .string(newName)])
        )
        
        // Also update the local session
        if var currentSession = authService.session {
            let updatedUser = User(
                id: currentSession.user.id,
                email: currentSession.user.email,
                name: newName,
                createdAt: currentSession.user.createdAt
            )
            
            let updatedSession = AuthSession(
                user: updatedUser,
                accessToken: currentSession.accessToken,
                refreshToken: currentSession.refreshToken
            )
            
            await MainActor.run {
                authService.session = updatedSession
            }
        }
    }
    
    func updateUserHandicap(handicap: Double?) async throws {
        guard let userId = authService.session?.user.id else {
            throw NSError(domain: "SupabaseDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Create or update user stats with new handicap
        struct HandicapUpdate: Encodable {
            let user_id: String
            let handicap_index: Double?
            let updated_at: String
        }
        
        let handicapData = HandicapUpdate(
            user_id: userId,
            handicap_index: handicap,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("user_golf_stats")
            .upsert(handicapData)
            .execute()
    }
    
    // MARK: - Helper Methods
    
    func refreshData() async {
        await fetchDashboardData()
    }
    
    func clearData() {
        dashboardData = DashboardData()
    }
    
    private func calculateHoleScoreStatistics(userId: String) async throws -> (birdies: Int, eagles: Int, pars: Int, bogeys: Int) {
        // Fetch all hole scores for the user
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
        
        return (birdies, eagles, pars, bogeys)
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