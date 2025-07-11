//
//  MockServices.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Foundation
import Combine
@testable import GolfTracker

// MARK: - Mock Config Loader

class MockConfigLoader {
    static var mockConfig: AppConfig?
    static var shouldThrowError = false
    static var errorToThrow: ConfigError = .configFileNotFound
    
    static func loadConfig() throws -> AppConfig {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockConfig ?? MockAppConfig.testConfig
    }
    
    static func reset() {
        mockConfig = nil
        shouldThrowError = false
        errorToThrow = .configFileNotFound
    }
}

// MARK: - Mock Auth Service

@MainActor
class MockSupabaseAuthService: ObservableObject {
    @Published var session: AuthSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Test control properties
    var shouldSucceedSignUp = true
    var shouldSucceedSignIn = true
    var shouldSucceedSignOut = true
    var simulateNetworkDelay = false
    
    private var mockSession: AuthSession?
    
    init(withSession: Bool = false) {
        if withSession {
            let user = TestDataFactory.createTestUser()
            self.session = TestDataFactory.createTestAuthSession(user: user)
            self.mockSession = self.session
        }
    }
    
    func checkSession() async {
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        session = mockSession
    }
    
    func signUp(email: String, password: String, name: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        isLoading = false
        
        if shouldSucceedSignUp {
            let user = TestDataFactory.createTestUser(email: email, name: name)
            let authSession = TestDataFactory.createTestAuthSession(user: user)
            session = authSession
            mockSession = authSession
            return true
        } else {
            errorMessage = "Sign up failed"
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        isLoading = false
        
        if shouldSucceedSignIn {
            let user = TestDataFactory.createTestUser(email: email)
            let authSession = TestDataFactory.createTestAuthSession(user: user)
            session = authSession
            mockSession = authSession
            return true
        } else {
            errorMessage = "Sign in failed"
            return false
        }
    }
    
    func signOut() async {
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        if shouldSucceedSignOut {
            session = nil
            mockSession = nil
            errorMessage = nil
        } else {
            errorMessage = "Sign out failed"
        }
    }
    
    // Test helper methods
    func setMockSession(_ session: AuthSession?) {
        self.session = session
        self.mockSession = session
    }
    
    func simulateError(_ message: String) {
        errorMessage = message
    }
}

// MARK: - Mock Data Service

@MainActor
class MockSupabaseDataService: ObservableObject {
    @Published var dashboardData = DashboardData(isLoading: false)
    
    // Test control properties
    var shouldSucceedFetch = true
    var shouldSucceedCreate = true
    var shouldSucceedUpdate = true
    var simulateNetworkDelay = false
    var mockRounds: [GolfRound] = []
    var mockStats: UserGolfStats?
    
    init() {
        setupDefaultMockData()
    }
    
    private func setupDefaultMockData() {
        mockRounds = [
            TestDataFactory.createTestGolfRound(id: "round1", totalScore: 85),
            TestDataFactory.createTestGolfRound(id: "round2", totalScore: 78),
            TestDataFactory.createTestGolfRound(id: "round3", totalScore: 92)
        ]
        
        mockStats = TestDataFactory.createTestUserGolfStats()
    }
    
    func fetchDashboardData() async {
        dashboardData = DashboardData(isLoading: true)
        
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        if shouldSucceedFetch {
            dashboardData = DashboardData(
                userStats: mockStats,
                recentRounds: Array(mockRounds.prefix(5)),
                isLoading: false,
                errorMessage: nil
            )
        } else {
            dashboardData = DashboardData(
                isLoading: false,
                errorMessage: "Failed to fetch dashboard data"
            )
        }
    }
    
    func createGolfRound(_ request: CreateRoundRequest) async throws -> GolfRound {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        if !shouldSucceedCreate {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create round"])
        }
        
        let newRound = TestDataFactory.createTestGolfRound(
            id: UUID().uuidString,
            courseName: request.courseName,
            totalScore: request.totalScore,
            par: request.par
        )
        
        mockRounds.insert(newRound, at: 0)
        await fetchDashboardData() // Refresh dashboard
        
        return newRound
    }
    
    func updateUserName(newName: String) async throws {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        if !shouldSucceedUpdate {
            throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to update name"])
        }
        
        // Mock success - in real app this would update the user name
    }
    
    func updateUserHandicap(handicap: Double?) async throws {
        if simulateNetworkDelay {
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        if !shouldSucceedUpdate {
            throw NSError(domain: "MockError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to update handicap"])
        }
        
        // Update mock stats
        if let stats = mockStats {
            mockStats = UserGolfStats(
                userId: stats.userId,
                totalRounds: stats.totalRounds,
                averageScore: stats.averageScore,
                bestScore: stats.bestScore,
                worstScore: stats.worstScore,
                handicapIndex: handicap,
                totalBirdies: stats.totalBirdies,
                totalEagles: stats.totalEagles,
                totalPars: stats.totalPars,
                totalBogeys: stats.totalBogeys,
                favoriteCourse: stats.favoriteCourse,
                lastPlayedDate: stats.lastPlayedDate,
                updatedAt: Date()
            )
        }
    }
    
    func refreshData() async {
        await fetchDashboardData()
    }
    
    func clearData() {
        dashboardData = DashboardData()
    }
    
    // Test helper methods
    func setMockRounds(_ rounds: [GolfRound]) {
        mockRounds = rounds
    }
    
    func setMockStats(_ stats: UserGolfStats?) {
        mockStats = stats
    }
    
    func reset() {
        shouldSucceedFetch = true
        shouldSucceedCreate = true
        shouldSucceedUpdate = true
        simulateNetworkDelay = false
        setupDefaultMockData()
        dashboardData = DashboardData(isLoading: false)
    }
}

// MARK: - Mock Golf Course API Service

@MainActor
class MockGolfCourseAPIService: ObservableObject {
    @Published var searchResults: [CourseSearchResult] = []
    @Published var allCourses: [CourseSearchResult] = []
    @Published var isSearching = false
    @Published var isLoadingAll = false
    @Published var searchError: String?
    @Published var showingCreateCourse = false
    
    // Test control properties
    var shouldSucceedSearch = true
    var shouldSucceedLoadAll = true
    var simulateNetworkDelay = false
    var mockSearchResults: [CourseSearchResult] = []
    var mockAllCourses: [CourseSearchResult] = []
    
    init() {
        setupDefaultMockData()
    }
    
    private func setupDefaultMockData() {
        mockSearchResults = [
            CourseSearchResult(id: 1, name: "Test Golf Club", location: "Test City", country: "Test Country", totalHoles: 18),
            CourseSearchResult(id: 2, name: "Mock Golf Course", location: "Mock City", country: "Test Country", totalHoles: 18),
            CourseSearchResult(id: 3, name: "Sample Golf Resort", location: "Sample City", country: "Test Country", totalHoles: 18)
        ]
        
        mockAllCourses = mockSearchResults + [
            CourseSearchResult(id: 4, name: "Additional Course 1", location: "City 4", country: "Test Country", totalHoles: 9),
            CourseSearchResult(id: 5, name: "Additional Course 2", location: "City 5", country: "Test Country", totalHoles: 18)
        ]
    }
    
    func searchGolfCourses(query: String) async {
        isSearching = true
        searchError = nil
        
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        isSearching = false
        
        if shouldSucceedSearch {
            // Filter mock results based on query
            if query.isEmpty {
                searchResults = []
            } else {
                searchResults = mockSearchResults.filter { course in
                    course.name.localizedCaseInsensitiveContains(query) ||
                    course.location.localizedCaseInsensitiveContains(query)
                }
            }
        } else {
            searchError = "Search failed"
            searchResults = []
        }
    }
    
    func loadAllCourses() async {
        isLoadingAll = true
        searchError = nil
        
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        isLoadingAll = false
        
        if shouldSucceedLoadAll {
            allCourses = mockAllCourses
        } else {
            searchError = "Failed to load courses"
            allCourses = []
        }
    }
    
    func getScorecard(for courseId: Int) async -> APIScorecard? {
        if simulateNetworkDelay {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        if shouldSucceedSearch {
            return TestDataFactory.createTestAPIScorecard(golfCourseId: courseId)
        } else {
            return nil
        }
    }
    
    func clearSearch() {
        searchResults = []
        searchError = nil
        isSearching = false
    }
    
    // Test helper methods
    func setMockSearchResults(_ results: [CourseSearchResult]) {
        mockSearchResults = results
    }
    
    func setMockAllCourses(_ courses: [CourseSearchResult]) {
        mockAllCourses = courses
    }
    
    func reset() {
        shouldSucceedSearch = true
        shouldSucceedLoadAll = true
        simulateNetworkDelay = false
        setupDefaultMockData()
        clearSearch()
        allCourses = []
        isLoadingAll = false
    }
} 