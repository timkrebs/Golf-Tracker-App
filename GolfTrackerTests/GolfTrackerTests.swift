//
//  GolfTrackerTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Testing
import Foundation
@testable import GolfTracker

@MainActor
struct GolfTrackerTests {

    // MARK: - Integration Tests
    
    @Test func fullGolfRoundWorkflow() async throws {
        // This test verifies the complete workflow from creating a round to saving it
        
        // Given
        let authService = await MockSupabaseAuthService(withSession: true)
        let dataService = await MockSupabaseDataService()
        
        // Create a complete golf round
        let holes = (1...18).map { holeNumber in
            CreateHoleScoreRequest(
                holeNumber: holeNumber,
                par: holeNumber <= 4 ? 4 : (holeNumber <= 14 ? 3 : 5),
                strokes: Int.random(in: 3...7),
                putts: Int.random(in: 1...3),
                fairwayHit: Bool.random(),
                greenInRegulation: Bool.random()
            )
        }
        
        let request = CreateRoundRequest(
            courseName: "Integration Test Course",
            date: Date(),
            totalScore: holes.reduce(0) { $0 + $1.strokes },
            par: holes.reduce(0) { $0 + $1.par },
            holes: holes,
            notes: "Integration test round"
        )
        
        // When
        let createdRound = try await dataService.createGolfRound(request)
        
        // Then
        #expect(createdRound.courseName == "Integration Test Course")
        #expect(createdRound.holes.count == 18)
        #expect(createdRound.totalScore == holes.reduce(0) { $0 + $1.strokes })
        #expect(TestAssertions.assertValidGolfRound(createdRound))
        
        // Verify the round appears in dashboard data
        await dataService.fetchDashboardData()
        #expect(dataService.dashboardData.recentRounds.contains { $0.courseName == "Integration Test Course" })
    }
    
    @Test func authenticationAndDataFlowIntegration() async throws {
        // Test the integration between authentication and data services
        
        // Given
        let authService = await MockSupabaseAuthService()
        let dataService = await MockSupabaseDataService()
        
        // Initially no session
        #expect(authService.session == nil)
        #expect(dataService.dashboardData.userStats != nil) // Mock has default data
        
        // When - Sign in
        let signInResult = await authService.signIn(email: "integration@test.com", password: "password123")
        
        // Then
        #expect(signInResult == true)
        #expect(authService.session != nil)
        #expect(authService.session?.user.email == "integration@test.com")
        
        // Data should be available after authentication
        await dataService.fetchDashboardData()
        #expect(dataService.dashboardData.userStats != nil)
        #expect(!dataService.dashboardData.recentRounds.isEmpty)
        
        // When - Sign out
        await authService.signOut()
        
        // Then
        #expect(authService.session == nil)
        
        // Data should be cleared
        await dataService.clearData()
        #expect(dataService.dashboardData.userStats == nil)
        #expect(dataService.dashboardData.recentRounds.isEmpty)
    }
    
    @Test func golfCourseSearchAndRoundCreationIntegration() async throws {
        // Test integration between course search and round creation
        
        // Given
        let apiService = await MockGolfCourseAPIService()
        let dataService = await MockSupabaseDataService()
        
        // When - Search for a course
        await apiService.searchGolfCourses(query: "Test Golf")
        
        // Then - Should find courses
        #expect(!apiService.searchResults.isEmpty)
        
        guard let selectedCourse = apiService.searchResults.first else {
            throw TestError.missingTestData
        }
        
        // When - Get scorecard for selected course
        let scorecard = await apiService.getScorecard(for: selectedCourse.id)
        
        // Then
        #expect(scorecard != nil)
        #expect(scorecard?.golfCourseId == selectedCourse.id)
        
        // When - Create round based on scorecard
        let holes = scorecard!.holes.map { hole in
            CreateHoleScoreRequest(
                holeNumber: hole.holeNumber,
                par: hole.par,
                strokes: hole.par + Int.random(in: -1...3),
                putts: Int.random(in: 1...3),
                fairwayHit: Bool.random(),
                greenInRegulation: Bool.random()
            )
        }
        
        let request = CreateRoundRequest(
            courseName: scorecard!.golfCourseName,
            date: Date(),
            totalScore: holes.reduce(0) { $0 + $1.strokes },
            par: scorecard!.totalPar,
            holes: holes,
            notes: "Round created from API course"
        )
        
        let createdRound = try await dataService.createGolfRound(request)
        
        // Then
        #expect(createdRound.courseName == scorecard!.golfCourseName)
        #expect(createdRound.par == scorecard!.totalPar)
        #expect(createdRound.holes.count == scorecard!.holes.count)
    }
    
    @Test func userProfileAndStatisticsIntegration() async throws {
        // Test integration between user profile updates and statistics
        
        // Given
        _ = await MockSupabaseAuthService(withSession: true)
        let dataService = await MockSupabaseDataService()
        
        let originalHandicap = dataService.dashboardData.userStats?.handicapIndex
        
        // When - Update user handicap
        try await dataService.updateUserHandicap(handicap: 18.5)
        
        // Then
        #expect(dataService.mockStats?.handicapIndex == 18.5)
        #expect(dataService.mockStats?.handicapIndex != originalHandicap)
        
        // When - Create a round with the new handicap context
        let request = CreateRoundRequest(
            courseName: "Handicap Test Course",
            date: Date(),
            totalScore: 95, // High score for high handicap
            par: 72,
            holes: [],
            notes: "Testing with updated handicap"
        )
        
        let createdRound = try await dataService.createGolfRound(request)
        
        // Then
        #expect(createdRound.totalScore == 95)
        #expect(createdRound.scoreRelativeToPar == 23) // 95 - 72
        
        // Verify round appears in dashboard
        await dataService.fetchDashboardData()
        #expect(dataService.dashboardData.recentRounds.contains { $0.courseName == "Handicap Test Course" })
    }
    
    @Test func inProgressRoundToCompletedRoundWorkflow() async throws {
        // Test the workflow from in-progress round to completed round
        
        // Given
        let inProgressRound = TestDataFactory.createTestInProgressRound(
            courseName: "Workflow Test Course",
            numberOfHoles: 9
        )
        
        // Simulate playing through holes
        for i in 0..<9 {
            inProgressRound.holes[i].strokes = Int.random(in: 3...6)
            inProgressRound.holes[i].putts = Int.random(in: 1...3)
        }
        
        // Verify round is ready to finish
        #expect(inProgressRound.isReadyToFinish)
        
        // When - Convert to complete round
        let dataService = await MockSupabaseDataService()
        let completedRequest = CreateRoundRequest(
            courseName: inProgressRound.courseName,
            date: Date(),
            totalScore: inProgressRound.totalScore,
            par: inProgressRound.totalPar,
            holes: inProgressRound.holes.map { hole in
                CreateHoleScoreRequest(
                    holeNumber: hole.holeNumber,
                    par: hole.par,
                    strokes: hole.strokes ?? 0,
                    putts: hole.putts,
                    fairwayHit: hole.fairwayHit,
                    greenInRegulation: hole.greenInRegulation
                )
            },
            notes: "Converted from in-progress round"
        )
        
        let completedRound = try await dataService.createGolfRound(completedRequest)
        
        // Then
        #expect(completedRound.courseName == "Workflow Test Course")
        #expect(completedRound.holes.count == 9)
        #expect(completedRound.totalScore == inProgressRound.totalScore)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func errorHandlingAndRecoveryIntegration() async throws {
        // Test error scenarios and recovery
        
        // Given
        let authService = await MockSupabaseAuthService()
        let dataService = await MockSupabaseDataService()
        let apiService = await MockGolfCourseAPIService()
        
        // When - Configure services to fail
        authService.shouldSucceedSignIn = false
        dataService.shouldSucceedFetch = false
        apiService.shouldSucceedSearch = false
        
        // Then - Should handle failures gracefully
        let signInResult = await authService.signIn(email: "test@test.com", password: "password")
        #expect(signInResult == false)
        
        await dataService.fetchDashboardData()
        await apiService.searchGolfCourses(query: "Test")
        
        #expect(authService.errorMessage != nil)
        #expect(dataService.dashboardData.errorMessage != nil)
        #expect(apiService.searchError != nil)
        
        // When - Recovery by resetting to success
        authService.shouldSucceedSignIn = true
        dataService.shouldSucceedFetch = true
        apiService.shouldSucceedSearch = true
        
        // Then - Should work again
        let recoveredSignInResult = await authService.signIn(email: "test@test.com", password: "password")
        #expect(recoveredSignInResult == true)
        
        await dataService.fetchDashboardData()
        await apiService.searchGolfCourses(query: "Test")
        
        #expect(authService.errorMessage == nil)
        #expect(dataService.dashboardData.errorMessage == nil)
        #expect(apiService.searchError == nil)
    }
    
    // MARK: - Performance Tests
    
    @Test func concurrentOperationsPerformance() async throws {
        // Test performance with concurrent operations
        
        // Given
        let authService = await MockSupabaseAuthService()
        let dataService = await MockSupabaseDataService()
        let apiService = await MockGolfCourseAPIService()
        
        // Disable network delay for performance test
        authService.simulateNetworkDelay = false
        dataService.simulateNetworkDelay = false
        apiService.simulateNetworkDelay = false
        
        let startTime = Date()
        
        // When - Run concurrent operations
        async let fetchData: () = dataService.fetchDashboardData()
        async let searchCourses: () = apiService.searchGolfCourses(query: "Concurrent")
        async let loadAllCourses: () = apiService.loadAllCourses()
        
        // Wait for all to complete
        _ = await fetchData
        _ = await searchCourses
        _ = await loadAllCourses
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then - Operations should complete quickly
        #expect(duration < 1.0) // Should complete in under 1 second
        #expect(dataService.dashboardData.userStats != nil) // Data loaded
        #expect(!apiService.searchResults.isEmpty) // Search completed
        #expect(!apiService.allCourses.isEmpty) // Load all completed
    }
    
    @Test func dataConsistencyWithMultipleOperations() async throws {
        // Test data consistency across multiple operations
        
        // Given
        let dataService = await MockSupabaseDataService()
        
        // When - Perform multiple operations
        await dataService.fetchDashboardData()
        let initialRoundCount = dataService.dashboardData.recentRounds.count
        
        // Create multiple rounds
        for i in 1...3 {
            let request = CreateRoundRequest(
                courseName: "Consistency Test Course \(i)",
                date: Date(),
                totalScore: 80 + i,
                par: 72,
                holes: [],
                notes: "Round \(i)"
            )
            _ = try await dataService.createGolfRound(request)
        }
        
        // Refresh data
        await dataService.fetchDashboardData()
        
        // Then - Data should be consistent
        #expect(dataService.dashboardData.recentRounds.count >= initialRoundCount + 3)
        
        // All created rounds should be present
        for i in 1...3 {
            #expect(dataService.dashboardData.recentRounds.contains { $0.courseName == "Consistency Test Course \(i)" })
        }
    }
}

// MARK: - Test Error Types

enum TestError: Error {
    case missingTestData
    case invalidTestState
    case testTimeout
}
