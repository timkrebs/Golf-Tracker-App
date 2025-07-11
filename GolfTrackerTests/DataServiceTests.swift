//
//  DataServiceTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Testing
import Foundation
@testable import GolfTracker

@MainActor
struct DataServiceTests {
    
    // MARK: - Initialization Tests
    
    @Test func dataServiceInitialization() async throws {
        // Given & When
        let dataService = MockSupabaseDataService()
        
        // Then
        #expect(dataService.dashboardData.userStats != nil) // Mock service sets up default data
        #expect(!dataService.dashboardData.recentRounds.isEmpty)
        #expect(dataService.dashboardData.isLoading == false)
        #expect(dataService.dashboardData.errorMessage == nil)
    }
    
    // MARK: - Dashboard Data Fetching Tests
    
    @Test func successfulFetchDashboardData() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedFetch = true
        
        // When
        await dataService.fetchDashboardData()
        
        // Then
        #expect(dataService.dashboardData.userStats != nil)
        #expect(!dataService.dashboardData.recentRounds.isEmpty)
        #expect(dataService.dashboardData.isLoading == false)
        #expect(dataService.dashboardData.errorMessage == nil)
    }
    
    @Test func failedFetchDashboardData() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedFetch = false
        
        // When
        await dataService.fetchDashboardData()
        
        // Then
        #expect(dataService.dashboardData.userStats == nil)
        #expect(dataService.dashboardData.recentRounds.isEmpty)
        #expect(dataService.dashboardData.isLoading == false)
        #expect(dataService.dashboardData.errorMessage == "Failed to fetch dashboard data")
    }
    
    @Test func fetchDashboardDataWithNetworkDelay() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.simulateNetworkDelay = true
        dataService.shouldSucceedFetch = true
        
        let startTime = Date()
        
        // When
        await dataService.fetchDashboardData()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration >= 1.0) // Should take at least 1 second due to simulated delay
        #expect(dataService.dashboardData.isLoading == false)
        #expect(dataService.dashboardData.errorMessage == nil)
    }
    
    @Test func fetchDashboardDataLoadingState() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.simulateNetworkDelay = true
        
        // Start async fetch
        let fetchTask = Task {
            await dataService.fetchDashboardData()
        }
        
        // Immediately check loading state
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        #expect(dataService.dashboardData.isLoading == true)
        
        // Wait for completion
        await fetchTask.value
        #expect(dataService.dashboardData.isLoading == false)
    }
    
    // MARK: - Golf Round Creation Tests
    
    @Test func successfulCreateGolfRound() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedCreate = true
        
        let request = CreateRoundRequest(
            courseName: "Test Course",
            date: Date(),
            totalScore: 85,
            par: 72,
            holes: [
                CreateHoleScoreRequest(holeNumber: 1, par: 4, strokes: 5, putts: 2, fairwayHit: true, greenInRegulation: false)
            ],
            notes: "Great round!"
        )
        
        // When
        let createdRound = try await dataService.createGolfRound(request)
        
        // Then
        #expect(createdRound.courseName == "Test Course")
        #expect(createdRound.totalScore == 85)
        #expect(createdRound.par == 72)
        #expect(!createdRound.id.isEmpty)
    }
    
    @Test func failedCreateGolfRound() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedCreate = false
        
        let request = CreateRoundRequest(
            courseName: "Test Course",
            date: Date(),
            totalScore: 85,
            par: 72,
            holes: [],
            notes: nil
        )
        
        // When & Then
        do {
            _ = try await dataService.createGolfRound(request)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error.localizedDescription.contains("Failed to create round"))
        }
    }
    
    @Test func createGolfRoundUpdatesRecentRounds() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedCreate = true
        
        let initialRoundCount = dataService.dashboardData.recentRounds.count
        
        let request = CreateRoundRequest(
            courseName: "New Course",
            date: Date(),
            totalScore: 80,
            par: 72,
            holes: [],
            notes: "New round"
        )
        
        // When
        let createdRound = try await dataService.createGolfRound(request)
        
        // Then
        #expect(createdRound.courseName == "New Course")
        #expect(dataService.dashboardData.recentRounds.count >= initialRoundCount)
        
        // New round should be at the beginning (most recent)
        if let firstRound = dataService.dashboardData.recentRounds.first {
            #expect(firstRound.courseName == "New Course")
        }
    }
    
    @Test func createGolfRoundWithNetworkDelay() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedCreate = true
        dataService.simulateNetworkDelay = true
        
        let request = CreateRoundRequest(
            courseName: "Test Course",
            date: Date(),
            totalScore: 85,
            par: 72,
            holes: [],
            notes: nil
        )
        
        let startTime = Date()
        
        // When
        let createdRound = try await dataService.createGolfRound(request)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration >= 0.5) // Should take at least 0.5 seconds due to simulated delay
        #expect(createdRound.courseName == "Test Course")
    }
    
    // MARK: - User Profile Update Tests
    
    @Test func successfulUpdateUserName() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedUpdate = true
        
        // When
        do {
            try await dataService.updateUserName(newName: "Updated Name")
            // Should not throw
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "Should not throw error: \(error)")
        }
    }
    
    @Test func failedUpdateUserName() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedUpdate = false
        
        // When & Then
        do {
            try await dataService.updateUserName(newName: "Updated Name")
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error.localizedDescription.contains("Failed to update name"))
        }
    }
    
    @Test func successfulUpdateUserHandicap() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedUpdate = true
        
        let originalHandicap = dataService.mockStats?.handicapIndex
        
        // When
        try await dataService.updateUserHandicap(handicap: 12.5)
        
        // Then
        #expect(dataService.mockStats?.handicapIndex == 12.5)
        #expect(dataService.mockStats?.handicapIndex != originalHandicap)
    }
    
    @Test func updateUserHandicapToNil() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedUpdate = true
        
        // When
        try await dataService.updateUserHandicap(handicap: nil)
        
        // Then
        #expect(dataService.mockStats?.handicapIndex == nil)
    }
    
    @Test func failedUpdateUserHandicap() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedUpdate = false
        
        // When & Then
        do {
            try await dataService.updateUserHandicap(handicap: 15.0)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error.localizedDescription.contains("Failed to update handicap"))
        }
    }
    
    // MARK: - Data Refresh Tests
    
    @Test func refreshData() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedFetch = true
        
        // Modify dashboard data to simulate stale data
        dataService.dashboardData = DashboardData(errorMessage: "Stale data")
        #expect(dataService.dashboardData.errorMessage == "Stale data")
        
        // When
        await dataService.refreshData()
        
        // Then
        #expect(dataService.dashboardData.errorMessage == nil) // Should be refreshed
        #expect(dataService.dashboardData.userStats != nil)
        #expect(!dataService.dashboardData.recentRounds.isEmpty)
    }
    
    @Test func clearData() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        
        // Verify initial state has data
        #expect(dataService.dashboardData.userStats != nil)
        #expect(!dataService.dashboardData.recentRounds.isEmpty)
        
        // When
        dataService.clearData()
        
        // Then
        #expect(dataService.dashboardData.userStats == nil)
        #expect(dataService.dashboardData.recentRounds.isEmpty)
        #expect(dataService.dashboardData.isLoading == false)
        #expect(dataService.dashboardData.errorMessage == nil)
    }
    
    // MARK: - Mock Data Management Tests
    
    @Test func setMockRounds() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        let customRounds = [
            TestDataFactory.createTestGolfRound(id: "custom1", courseName: "Custom Course 1"),
            TestDataFactory.createTestGolfRound(id: "custom2", courseName: "Custom Course 2")
        ]
        
        // When
        dataService.setMockRounds(customRounds)
        await dataService.fetchDashboardData()
        
        // Then
        #expect(dataService.dashboardData.recentRounds.count >= 2)
        #expect(dataService.dashboardData.recentRounds.contains { $0.courseName == "Custom Course 1" })
        #expect(dataService.dashboardData.recentRounds.contains { $0.courseName == "Custom Course 2" })
    }
    
    @Test func setMockStats() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        let customStats = TestDataFactory.createTestUserGolfStats(
            totalRounds: 50,
            averageScore: 75.5,
            bestScore: 68,
            handicapIndex: 8.2
        )
        
        // When
        dataService.setMockStats(customStats)
        await dataService.fetchDashboardData()
        
        // Then
        #expect(dataService.dashboardData.userStats?.totalRounds == 50)
        #expect(dataService.dashboardData.userStats?.averageScore == 75.5)
        #expect(dataService.dashboardData.userStats?.bestScore == 68)
        #expect(dataService.dashboardData.userStats?.handicapIndex == 8.2)
    }
    
    @Test func setMockStatsToNil() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        
        // Verify initial state has stats
        #expect(dataService.mockStats != nil)
        
        // When
        dataService.setMockStats(nil)
        await dataService.fetchDashboardData()
        
        // Then
        #expect(dataService.dashboardData.userStats == nil)
    }
    
    // MARK: - Service Reset Tests
    
    @Test func resetService() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        
        // Modify service state
        dataService.shouldSucceedFetch = false
        dataService.shouldSucceedCreate = false
        dataService.shouldSucceedUpdate = false
        dataService.simulateNetworkDelay = true
        dataService.setMockRounds([])
        dataService.setMockStats(nil)
        dataService.clearData()
        
        // Verify modified state
        #expect(dataService.shouldSucceedFetch == false)
        #expect(dataService.dashboardData.userStats == nil)
        
        // When
        dataService.reset()
        
        // Then
        #expect(dataService.shouldSucceedFetch == true)
        #expect(dataService.shouldSucceedCreate == true)
        #expect(dataService.shouldSucceedUpdate == true)
        #expect(dataService.simulateNetworkDelay == false)
        #expect(dataService.dashboardData.userStats != nil) // Should have default mock data
        #expect(!dataService.dashboardData.recentRounds.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func multipleFailedOperations() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedFetch = false
        dataService.shouldSucceedCreate = false
        dataService.shouldSucceedUpdate = false
        
        // When & Then - Fetch should fail
        await dataService.fetchDashboardData()
        #expect(dataService.dashboardData.errorMessage != nil)
        
        // Create should fail
        let request = CreateRoundRequest(
            courseName: "Test",
            date: Date(),
            totalScore: 80,
            par: 72,
            holes: [],
            notes: nil
        )
        
        do {
            _ = try await dataService.createGolfRound(request)
            #expect(Bool(false), "Expected create to fail")
        } catch {
            // Expected
        }
        
        // Update should fail
        do {
            try await dataService.updateUserName(newName: "Test")
            #expect(Bool(false), "Expected update to fail")
        } catch {
            // Expected
        }
    }
    
    // MARK: - Data Consistency Tests
    
    @Test func dataConsistencyAfterOperations() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedCreate = true
        dataService.shouldSucceedUpdate = true
        
        let initialRoundCount = dataService.dashboardData.recentRounds.count
        let initialHandicap = dataService.dashboardData.userStats?.handicapIndex
        
        // When - Create a round
        let request = CreateRoundRequest(
            courseName: "Consistency Test Course",
            date: Date(),
            totalScore: 88,
            par: 72,
            holes: [],
            notes: "Testing data consistency"
        )
        
        let createdRound = try await dataService.createGolfRound(request)
        
        // Update handicap
        try await dataService.updateUserHandicap(handicap: 16.5)
        
        // Then
        #expect(createdRound.courseName == "Consistency Test Course")
        #expect(dataService.dashboardData.recentRounds.count >= initialRoundCount)
        #expect(dataService.dashboardData.userStats?.handicapIndex == 16.5)
        #expect(dataService.dashboardData.userStats?.handicapIndex != initialHandicap)
    }
    
    // MARK: - Performance Tests
    
    @Test func multipleSimultaneousRequests() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.simulateNetworkDelay = false // Keep fast for this test
        
        // When - Start multiple operations simultaneously
        async let fetch1 = dataService.fetchDashboardData()
        async let fetch2 = dataService.fetchDashboardData()
        async let refresh = dataService.refreshData()
        
        // Wait for all to complete
        await (fetch1, fetch2, refresh)
        
        // Then - Should complete without issues
        #expect(dataService.dashboardData.userStats != nil)
        #expect(!dataService.dashboardData.recentRounds.isEmpty)
        #expect(dataService.dashboardData.errorMessage == nil)
    }
    
    @Test func rapidSuccessiveUpdates() async throws {
        // Given
        let dataService = MockSupabaseDataService()
        dataService.shouldSucceedUpdate = true
        dataService.simulateNetworkDelay = false
        
        // When - Perform rapid successive updates
        try await dataService.updateUserHandicap(handicap: 10.0)
        try await dataService.updateUserHandicap(handicap: 11.0)
        try await dataService.updateUserHandicap(handicap: 12.0)
        try await dataService.updateUserName(newName: "Final Name")
        
        // Then - Last values should be set
        #expect(dataService.mockStats?.handicapIndex == 12.0)
    }
} 