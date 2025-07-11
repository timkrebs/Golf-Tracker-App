//
//  SupabaseDataService.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation
import Supabase

// MARK: - Helper Structures

struct HoleScoreStatistics {
    let birdies: Int
    let eagles: Int
    let pars: Int
    let bogeys: Int
}

struct BasicGolfStats {
    let totalRounds: Int
    let averageScore: Double
    let bestScore: Int?
    let worstScore: Int?
    let handicapIndex: Double?
    let favoriteCourse: String?
    let lastPlayedDate: Date?
}

struct UserStatsUpsert: Encodable {
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

struct RoundResponse: Codable {
    let id: String
    let userId: String
    let courseName: String
    let date: String
    let totalScore: Int
    let par: Int
    let notes: String
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

// MARK: - SupabaseDataService

@MainActor
class SupabaseDataService: ObservableObject {
    @Published var dashboardData = DashboardData(isLoading: true)
    
    private let supabase: SupabaseClient
    private let authService: SupabaseAuthService
    private let userStatsService: UserStatsService
    private let golfRoundsService: GolfRoundsService
    
    init(authService: SupabaseAuthService) {
        self.authService = authService
        self.userStatsService = UserStatsService()
        self.golfRoundsService = GolfRoundsService()
        
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
            async let userStats = userStatsService.fetchUserStats(userId: userId)
            async let recentRounds = golfRoundsService.fetchRecentRounds(userId: userId, limit: 5)
            
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
    
    // MARK: - Public Interface
    
    func createRound(_ request: CreateRoundRequest) async throws -> GolfRound {
        guard let userId = authService.session?.user.id else {
            throw NSError(domain: "SupabaseDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let createdRound = try await golfRoundsService.createRound(request, userId: userId)
        
        // Update user statistics and refresh data
        let allRounds = try await golfRoundsService.fetchAllRounds(userId: userId)
        try await userStatsService.updateUserStats(userId: userId, rounds: allRounds)
        await fetchDashboardData()
        
        return createdRound
    }
    
    func updateUserName(newName: String) async throws {
        guard let userId = authService.session?.user.id else {
            throw NSError(domain: "SupabaseDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Update user metadata in Supabase Auth using proper UserAttributes
        try await supabase.auth.update(
            user: .init(data: ["name": .string(newName)])
        )
        
        // Also update the local session
        await updateLocalSession(with: newName)
    }
    
    private func updateLocalSession(with newName: String) async {
        guard var currentSession = authService.session else { return }
        
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
    
    func updateUserHandicap(handicap: Double?) async throws {
        guard let userId = authService.session?.user.id else {
            throw NSError(domain: "SupabaseDataService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await userStatsService.updateUserHandicap(userId: userId, handicap: handicap)
    }
    
    func fetchRecentRounds(userId: String, limit: Int = 10) async throws -> [GolfRound] {
        return try await golfRoundsService.fetchRecentRounds(userId: userId, limit: limit)
    }
    
    func fetchAllRounds(userId: String) async throws -> [GolfRound] {
        return try await golfRoundsService.fetchAllRounds(userId: userId)
    }
    
    // MARK: - Helper Methods
    
    func refreshData() async {
        await fetchDashboardData()
    }
    
    func clearData() {
        dashboardData = DashboardData()
    }
} 
