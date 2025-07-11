//
//  APIServiceTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Testing
import Foundation
@testable import GolfTracker

@MainActor
struct APIServiceTests {
    
    // MARK: - Initialization Tests
    
    @Test func apiServiceInitialization() async throws {
        // Given & When
        let apiService = MockGolfCourseAPIService()
        
        // Then
        #expect(apiService.searchResults.isEmpty)
        #expect(apiService.allCourses.isEmpty)
        #expect(apiService.isSearching == false)
        #expect(apiService.isLoadingAll == false)
        #expect(apiService.searchError == nil)
        #expect(apiService.showingCreateCourse == false)
    }
    
    // MARK: - Search Golf Courses Tests
    
    @Test func successfulSearchGolfCourses() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        
        // When
        await apiService.searchGolfCourses(query: "Test")
        
        // Then
        #expect(!apiService.searchResults.isEmpty)
        #expect(apiService.isSearching == false)
        #expect(apiService.searchError == nil)
        
        // Results should contain courses matching "Test"
        let hasMatchingResults = apiService.searchResults.contains { course in
            course.name.localizedCaseInsensitiveContains("Test") ||
            course.location.localizedCaseInsensitiveContains("Test")
        }
        #expect(hasMatchingResults)
    }
    
    @Test func failedSearchGolfCourses() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = false
        
        // When
        await apiService.searchGolfCourses(query: "Test")
        
        // Then
        #expect(apiService.searchResults.isEmpty)
        #expect(apiService.isSearching == false)
        #expect(apiService.searchError == "Search failed")
    }
    
    @Test func searchWithEmptyQuery() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        
        // When
        await apiService.searchGolfCourses(query: "")
        
        // Then
        #expect(apiService.searchResults.isEmpty) // Empty query should return no results
        #expect(apiService.isSearching == false)
        #expect(apiService.searchError == nil)
    }
    
    @Test func searchWithSpecificQuery() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        
        // When
        await apiService.searchGolfCourses(query: "Golf Club")
        
        // Then
        #expect(!apiService.searchResults.isEmpty)
        
        // Should find "Test Golf Club" from mock data
        let hasGolfClub = apiService.searchResults.contains { $0.name == "Test Golf Club" }
        #expect(hasGolfClub)
    }
    
    @Test func searchCaseInsensitive() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        
        // When - Search with different cases
        await apiService.searchGolfCourses(query: "golf")
        let lowerCaseResults = apiService.searchResults.count
        
        await apiService.searchGolfCourses(query: "GOLF")
        let upperCaseResults = apiService.searchResults.count
        
        await apiService.searchGolfCourses(query: "Golf")
        let mixedCaseResults = apiService.searchResults.count
        
        // Then - Should return same number of results regardless of case
        #expect(lowerCaseResults == upperCaseResults)
        #expect(upperCaseResults == mixedCaseResults)
        #expect(lowerCaseResults > 0)
    }
    
    @Test func searchWithNetworkDelay() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        apiService.simulateNetworkDelay = true
        
        let startTime = Date()
        
        // When
        await apiService.searchGolfCourses(query: "Test")
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration >= 0.5) // Should take at least 0.5 seconds due to simulated delay
        #expect(!apiService.searchResults.isEmpty)
        #expect(apiService.isSearching == false)
    }
    
    @Test func searchLoadingState() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.simulateNetworkDelay = true
        
        // Start async search
        let searchTask = Task {
            await apiService.searchGolfCourses(query: "Test")
        }
        
        // Immediately check loading state
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        #expect(apiService.isSearching == true)
        
        // Wait for completion
        await searchTask.value
        #expect(apiService.isSearching == false)
    }
    
    // MARK: - Load All Courses Tests
    
    @Test func successfulLoadAllCourses() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedLoadAll = true
        
        // When
        await apiService.loadAllCourses()
        
        // Then
        #expect(!apiService.allCourses.isEmpty)
        #expect(apiService.isLoadingAll == false)
        #expect(apiService.searchError == nil)
        
        // Should contain more courses than search results (includes additional courses)
        #expect(apiService.allCourses.count >= apiService.mockSearchResults.count)
    }
    
    @Test func failedLoadAllCourses() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedLoadAll = false
        
        // When
        await apiService.loadAllCourses()
        
        // Then
        #expect(apiService.allCourses.isEmpty)
        #expect(apiService.isLoadingAll == false)
        #expect(apiService.searchError == "Failed to load courses")
    }
    
    @Test func loadAllCoursesWithNetworkDelay() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedLoadAll = true
        apiService.simulateNetworkDelay = true
        
        let startTime = Date()
        
        // When
        await apiService.loadAllCourses()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration >= 1.0) // Should take at least 1 second due to simulated delay
        #expect(!apiService.allCourses.isEmpty)
        #expect(apiService.isLoadingAll == false)
    }
    
    @Test func loadAllCoursesLoadingState() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.simulateNetworkDelay = true
        
        // Start async load
        let loadTask = Task {
            await apiService.loadAllCourses()
        }
        
        // Immediately check loading state
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        #expect(apiService.isLoadingAll == true)
        
        // Wait for completion
        await loadTask.value
        #expect(apiService.isLoadingAll == false)
    }
    
    // MARK: - Get Scorecard Tests
    
    @Test func successfulGetScorecard() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true // Uses same flag as search
        
        // When
        let scorecard = await apiService.getScorecard(for: 123)
        
        // Then
        #expect(scorecard != nil)
        #expect(scorecard?.golfCourseId == 123)
        #expect(scorecard?.holes.count == 18) // Default numberOfHoles in TestDataFactory
        #expect((scorecard?.totalPar ?? 0) > 0)
        #expect((scorecard?.totalDistance ?? 0) > 0)
    }
    
    @Test func failedGetScorecard() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = false
        
        // When
        let scorecard = await apiService.getScorecard(for: 123)
        
        // Then
        #expect(scorecard == nil)
    }
    
    @Test func getScorecardWithNetworkDelay() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        apiService.simulateNetworkDelay = true
        
        let startTime = Date()
        
        // When
        let scorecard = await apiService.getScorecard(for: 456)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration >= 0.5) // Should take at least 0.5 seconds due to simulated delay
        #expect(scorecard != nil)
        #expect(scorecard?.golfCourseId == 456)
    }
    
    // MARK: - Clear Search Tests
    
    @Test func clearSearch() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        
        // Set up some search state
        await apiService.searchGolfCourses(query: "Test")
        apiService.searchError = "Some error"
        
        // Verify initial state
        #expect(!apiService.searchResults.isEmpty || apiService.searchError != nil)
        
        // When
        apiService.clearSearch()
        
        // Then
        #expect(apiService.searchResults.isEmpty)
        #expect(apiService.searchError == nil)
        #expect(apiService.isSearching == false)
    }
    
    // MARK: - Mock Data Management Tests
    
    @Test func setMockSearchResults() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        let customResults = [
            CourseSearchResult(id: 100, name: "Custom Course 1", location: "Custom Location 1", country: "Test Country", totalHoles: 18),
            CourseSearchResult(id: 101, name: "Custom Course 2", location: "Custom Location 2", country: "Test Country", totalHoles: 9)
        ]
        
        // When
        apiService.setMockSearchResults(customResults)
        await apiService.searchGolfCourses(query: "Custom")
        
        // Then
        #expect(!apiService.searchResults.isEmpty)
        #expect(apiService.searchResults.contains { $0.name == "Custom Course 1" })
        #expect(apiService.searchResults.contains { $0.name == "Custom Course 2" })
    }
    
    @Test func setMockAllCourses() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        let customCourses = [
            CourseSearchResult(id: 200, name: "All Course 1", location: "All Location 1", country: "Test Country", totalHoles: 18),
            CourseSearchResult(id: 201, name: "All Course 2", location: "All Location 2", country: "Test Country", totalHoles: 18),
            CourseSearchResult(id: 202, name: "All Course 3", location: "All Location 3", country: "Test Country", totalHoles: 9)
        ]
        
        // When
        apiService.setMockAllCourses(customCourses)
        await apiService.loadAllCourses()
        
        // Then
        #expect(apiService.allCourses.count == 3)
        #expect(apiService.allCourses.contains { $0.name == "All Course 1" })
        #expect(apiService.allCourses.contains { $0.name == "All Course 2" })
        #expect(apiService.allCourses.contains { $0.name == "All Course 3" })
    }
    
    // MARK: - Service Reset Tests
    
    @Test func resetService() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        
        // Modify service state
        await apiService.searchGolfCourses(query: "Test")
        await apiService.loadAllCourses()
        apiService.shouldSucceedSearch = false
        apiService.shouldSucceedLoadAll = false
        apiService.simulateNetworkDelay = true
        apiService.searchError = "Test error"
        apiService.showingCreateCourse = true
        
        // Verify modified state
        #expect(!apiService.searchResults.isEmpty)
        #expect(!apiService.allCourses.isEmpty)
        #expect(apiService.shouldSucceedSearch == false)
        #expect(apiService.searchError != nil)
        
        // When
        apiService.reset()
        
        // Then
        #expect(apiService.shouldSucceedSearch == true)
        #expect(apiService.shouldSucceedLoadAll == true)
        #expect(apiService.simulateNetworkDelay == false)
        #expect(apiService.searchResults.isEmpty)
        #expect(apiService.allCourses.isEmpty)
        #expect(apiService.searchError == nil)
        #expect(apiService.isLoadingAll == false)
        #expect(apiService.isSearching == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func multipleFailedOperations() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = false
        apiService.shouldSucceedLoadAll = false
        
        // When & Then - Search should fail
        await apiService.searchGolfCourses(query: "Test")
        #expect(apiService.searchResults.isEmpty)
        #expect(apiService.searchError == "Search failed")
        
        // Load all should fail
        await apiService.loadAllCourses()
        #expect(apiService.allCourses.isEmpty)
        #expect(apiService.searchError == "Failed to load courses")
        
        // Get scorecard should fail
        let scorecard = await apiService.getScorecard(for: 123)
        #expect(scorecard == nil)
    }
    
    @Test func errorStatePersistence() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = false
        
        // When - Fail a search
        await apiService.searchGolfCourses(query: "Test")
        #expect(apiService.searchError == "Search failed")
        
        // Subsequent successful search should clear error
        apiService.shouldSucceedSearch = true
        await apiService.searchGolfCourses(query: "Test")
        
        // Then
        #expect(apiService.searchError == nil)
        #expect(!apiService.searchResults.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    @Test func multipleSimultaneousSearches() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.simulateNetworkDelay = false // Keep fast for this test
        
        // When - Start multiple searches simultaneously
        async let search1 = apiService.searchGolfCourses(query: "Golf")
        async let search2 = apiService.searchGolfCourses(query: "Test")
        async let search3 = apiService.searchGolfCourses(query: "Course")
        
        // Wait for all to complete
        await (search1, search2, search3)
        
        // Then - Should complete without issues, last search result should be present
        #expect(!apiService.searchResults.isEmpty)
        #expect(apiService.isSearching == false)
        #expect(apiService.searchError == nil)
    }
    
    @Test func searchAndLoadSimultaneously() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.simulateNetworkDelay = false
        
        // When - Start search and load all simultaneously
        async let search = apiService.searchGolfCourses(query: "Test")
        async let loadAll = apiService.loadAllCourses()
        
        // Wait for both to complete
        await (search, loadAll)
        
        // Then - Both should complete successfully
        #expect(!apiService.searchResults.isEmpty)
        #expect(!apiService.allCourses.isEmpty)
        #expect(apiService.isSearching == false)
        #expect(apiService.isLoadingAll == false)
        #expect(apiService.searchError == nil)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func searchWithSpecialCharacters() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        
        // When
        await apiService.searchGolfCourses(query: "Golf & Country Club")
        
        // Then - Should handle special characters gracefully
        #expect(apiService.isSearching == false)
        #expect(apiService.searchError == nil)
    }
    
    @Test func searchWithVeryLongQuery() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        let longQuery = String(repeating: "Very Long Golf Course Name ", count: 10)
        
        // When
        await apiService.searchGolfCourses(query: longQuery)
        
        // Then - Should handle long queries gracefully
        #expect(apiService.isSearching == false)
        #expect(apiService.searchError == nil)
    }
    
    @Test func getScorecardWithInvalidCourseId() async throws {
        // Given
        let apiService = MockGolfCourseAPIService()
        apiService.shouldSucceedSearch = true
        
        // When
        let scorecard = await apiService.getScorecard(for: -1)
        
        // Then - Should handle invalid IDs gracefully
        #expect(scorecard?.golfCourseId == -1) // Mock service returns scorecard with requested ID
    }
} 