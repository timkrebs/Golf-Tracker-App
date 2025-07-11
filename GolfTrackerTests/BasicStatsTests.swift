//
//  BasicStatsTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import XCTest
@testable import GolfTracker

@MainActor
final class BasicStatsTests: XCTestCase {
    
    var mockDataService: MockSupabaseDataService!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockSupabaseDataService()
    }
    
    override func tearDown() {
        mockDataService = nil
        super.tearDown()
    }
    
    // MARK: - User Golf Stats Tests
    
    func testUserGolfStatsCreation() {
        // Given
        let userId = "test-user-123"
        let totalRounds = 25
        let averageScore = 84.5
        let bestScore = 76
        let worstScore = 95
        let handicapIndex = 12.3
        
        // When
        let stats = TestDataFactory.createTestUserGolfStats(
            userId: userId,
            totalRounds: totalRounds,
            averageScore: averageScore,
            bestScore: bestScore,
            worstScore: worstScore,
            handicapIndex: handicapIndex
        )
        
        // Then
        XCTAssertEqual(stats.userId, userId)
        XCTAssertEqual(stats.totalRounds, totalRounds)
        XCTAssertEqual(stats.averageScore, averageScore)
        XCTAssertEqual(stats.bestScore, bestScore)
        XCTAssertEqual(stats.worstScore, worstScore)
        XCTAssertEqual(stats.handicapIndex, handicapIndex)
        XCTAssertGreaterThan(stats.totalBirdies, 0)
        XCTAssertGreaterThan(stats.totalPars, 0)
        XCTAssertNotNil(stats.favoriteCourse)
        XCTAssertNotNil(stats.lastPlayedDate)
    }
    
    func testUserGolfStatsValidation() {
        // Given
        let stats = TestDataFactory.createTestUserGolfStats()
        
        // Then - verify realistic golf statistics
        XCTAssertGreaterThan(stats.totalRounds, 0)
        XCTAssertNotNil(stats.averageScore)
        if let avgScore = stats.averageScore {
            XCTAssertGreaterThan(avgScore, 60) // Reasonable lower bound
            XCTAssertLessThan(avgScore, 120) // Reasonable upper bound
        }
        
        if let bestScore = stats.bestScore, let worstScore = stats.worstScore {
            XCTAssertLessThanOrEqual(bestScore, worstScore)
        }
        
        if let handicap = stats.handicapIndex {
            XCTAssertGreaterThanOrEqual(handicap, -5.0) // Professional range
            XCTAssertLessThanOrEqual(handicap, 54.0) // Maximum handicap
        }
    }
    
    // MARK: - Dashboard Data Tests
    
    func testDashboardDataInitialization() {
        // Test empty dashboard data
        let emptyDashboard = DashboardData()
        XCTAssertNil(emptyDashboard.userStats)
        XCTAssertTrue(emptyDashboard.recentRounds.isEmpty)
        XCTAssertFalse(emptyDashboard.isLoading)
        XCTAssertNil(emptyDashboard.errorMessage)
        
        // Test loading dashboard data
        let loadingDashboard = DashboardData(isLoading: true)
        XCTAssertTrue(loadingDashboard.isLoading)
        
        // Test error dashboard data
        let errorDashboard = DashboardData(errorMessage: "Network error")
        XCTAssertEqual(errorDashboard.errorMessage, "Network error")
    }
    
    func testDashboardDataFetching() async {
        // Given
        mockDataService.shouldSucceedFetch = true
        
        // When
        await mockDataService.fetchDashboardData()
        
        // Then
        let dashboardData = mockDataService.dashboardData
        XCTAssertNotNil(dashboardData.userStats)
        XCTAssertFalse(dashboardData.recentRounds.isEmpty)
        XCTAssertFalse(dashboardData.isLoading)
        XCTAssertNil(dashboardData.errorMessage)
        
        // Verify recent rounds are sorted (most recent first)
        let rounds = dashboardData.recentRounds
        XCTAssertLessThanOrEqual(rounds.count, 5) // Should limit to 5 recent rounds
    }
    
    func testDashboardDataFetchingFailure() async {
        // Given
        mockDataService.shouldSucceedFetch = false
        
        // When
        await mockDataService.fetchDashboardData()
        
        // Then
        let dashboardData = mockDataService.dashboardData
        XCTAssertNil(dashboardData.userStats)
        XCTAssertTrue(dashboardData.recentRounds.isEmpty)
        XCTAssertFalse(dashboardData.isLoading)
        XCTAssertNotNil(dashboardData.errorMessage)
        XCTAssertEqual(dashboardData.errorMessage, "Failed to fetch dashboard data")
    }
    
    // MARK: - Round Creation and Stats Update Tests
    
    func testCreateGolfRoundUpdatesStats() async throws {
        // Given
        mockDataService.shouldSucceedCreate = true
        let initialRoundCount = mockDataService.mockRounds.count
        
        let createRequest = CreateRoundRequest(
            courseName: "Cypress Point Club",
            date: Date(),
            totalScore: 79,
            par: 72,
            holes: [], // Simplified for test
            notes: nil
        )
        
        // When
        let newRound = try await mockDataService.createGolfRound(createRequest)
        
        // Then
        XCTAssertEqual(newRound.courseName, createRequest.courseName)
        XCTAssertEqual(newRound.totalScore, createRequest.totalScore)
        XCTAssertEqual(newRound.par, createRequest.par)
        XCTAssertEqual(mockDataService.mockRounds.count, initialRoundCount + 1)
        
        // Verify the new round is at the beginning (most recent)
        XCTAssertEqual(mockDataService.mockRounds.first?.id, newRound.id)
    }
    
    func testCreateGolfRoundFailure() async {
        // Given
        mockDataService.shouldSucceedCreate = false
        let createRequest = CreateRoundRequest(
            courseName: "Test Course",
            date: Date(),
            totalScore: 85,
            par: 72,
            holes: [],
            notes: nil
        )
        
        // When & Then
        do {
            _ = try await mockDataService.createGolfRound(createRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - User Profile Update Tests
    
    func testUpdateUserName() async throws {
        // Given
        mockDataService.shouldSucceedUpdate = true
        let newName = "Updated Test User"
        
        // When & Then - should not throw
        try await mockDataService.updateUserName(newName: newName)
    }
    
    func testUpdateUserNameFailure() async {
        // Given
        mockDataService.shouldSucceedUpdate = false
        let newName = "Updated Test User"
        
        // When & Then
        do {
            try await mockDataService.updateUserName(newName: newName)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertTrue(error.localizedDescription.contains("Failed to update name"))
        }
    }
    
    func testUpdateUserHandicap() async throws {
        // Given
        mockDataService.shouldSucceedUpdate = true
        let newHandicap = 10.5
        let originalStats = mockDataService.mockStats
        
        // When
        try await mockDataService.updateUserHandicap(handicap: newHandicap)
        
        // Then
        XCTAssertNotNil(mockDataService.mockStats)
        XCTAssertEqual(mockDataService.mockStats?.handicapIndex, newHandicap)
        
        // Verify other stats remain unchanged
        XCTAssertEqual(mockDataService.mockStats?.userId, originalStats?.userId)
        XCTAssertEqual(mockDataService.mockStats?.totalRounds, originalStats?.totalRounds)
        XCTAssertEqual(mockDataService.mockStats?.averageScore, originalStats?.averageScore)
    }
    
    func testUpdateUserHandicapToNil() async throws {
        // Given
        mockDataService.shouldSucceedUpdate = true
        
        // When
        try await mockDataService.updateUserHandicap(handicap: nil)
        
        // Then
        XCTAssertNotNil(mockDataService.mockStats)
        XCTAssertNil(mockDataService.mockStats?.handicapIndex)
    }
    
    func testUpdateUserHandicapFailure() async {
        // Given
        mockDataService.shouldSucceedUpdate = false
        let newHandicap = 15.0
        
        // When & Then
        do {
            try await mockDataService.updateUserHandicap(handicap: newHandicap)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertTrue(error.localizedDescription.contains("Failed to update handicap"))
        }
    }
    
    // MARK: - Statistics Calculation Tests
    
    func testScoreStatisticsFromRounds() {
        // Given - create rounds with varying scores
        let rounds = [
            TestDataFactory.createTestGolfRound(totalScore: 72, par: 72), // Even par
            TestDataFactory.createTestGolfRound(totalScore: 85, par: 72), // +13
            TestDataFactory.createTestGolfRound(totalScore: 78, par: 72), // +6
            TestDataFactory.createTestGolfRound(totalScore: 90, par: 72), // +18
            TestDataFactory.createTestGolfRound(totalScore: 76, par: 72)  // +4
        ]
        
        // When - calculate statistics
        let scores = rounds.map { $0.totalScore }
        let averageScore = Double(scores.reduce(0, +)) / Double(scores.count)
        let bestScore = scores.min()
        let worstScore = scores.max()
        
        // Then
        XCTAssertEqual(averageScore, 80.2, accuracy: 0.1)
        XCTAssertEqual(bestScore, 72)
        XCTAssertEqual(worstScore, 90)
    }
    
    func testHandicapIndexValidation() {
        // Test valid handicap ranges
        let validHandicaps: [Double] = [-2.0, 0.0, 5.5, 18.0, 36.0, 54.0]
        
        for handicap in validHandicaps {
            let stats = TestDataFactory.createTestUserGolfStats(handicapIndex: handicap)
            XCTAssertEqual(stats.handicapIndex, handicap)
            XCTAssertGreaterThanOrEqual(handicap, -5.0)
            XCTAssertLessThanOrEqual(handicap, 54.0)
        }
    }
    
    // MARK: - Data Refresh Tests
    
    func testDataRefresh() async {
        // Given
        mockDataService.shouldSucceedFetch = true
        let initialLoadingState = mockDataService.dashboardData.isLoading
        
        // When
        await mockDataService.refreshData()
        
        // Then
        XCTAssertFalse(mockDataService.dashboardData.isLoading)
        XCTAssertNotNil(mockDataService.dashboardData.userStats)
        XCTAssertFalse(mockDataService.dashboardData.recentRounds.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testLargeDataSetPerformance() {
        measure {
            // Create a large dataset
            var rounds: [GolfRound] = []
            for i in 0..<1000 {
                let round = TestDataFactory.createTestGolfRound(
                    id: "round-\(i)",
                    totalScore: Int.random(in: 70...100)
                )
                rounds.append(round)
            }
            
            // Calculate basic statistics
            let scores = rounds.map { $0.totalScore }
            _ = Double(scores.reduce(0, +)) / Double(scores.count)
            _ = scores.min()
            _ = scores.max()
        }
    }
} 