//
//  ModelTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Testing
import Foundation
@testable import GolfTracker

struct ModelTests {
    
    // MARK: - User Model Tests
    
    @Test func userModelCreation() async throws {
        // Given
        let user = TestDataFactory.createTestUser(
            id: "user123",
            email: "test@golf.com",
            name: "Golf Player"
        )
        
        // Then
        #expect(user.id == "user123")
        #expect(user.email == "test@golf.com")
        #expect(user.name == "Golf Player")
        #expect(user.createdAt != nil)
    }
    
    @Test func userEquality() async throws {
        // Given
        let user1 = TestDataFactory.createTestUser(id: "123", email: "test@example.com", name: "Test")
        let user2 = TestDataFactory.createTestUser(id: "123", email: "test@example.com", name: "Test")
        let user3 = TestDataFactory.createTestUser(id: "456", email: "other@example.com", name: "Other")
        
        // Then
        #expect(user1 == user2)
        #expect(user1 != user3)
    }
    
    @Test func authSessionEquality() async throws {
        // Given
        let user = TestDataFactory.createTestUser()
        let session1 = TestDataFactory.createTestAuthSession(user: user, accessToken: "token1")
        let session2 = TestDataFactory.createTestAuthSession(user: user, accessToken: "token1")
        let session3 = TestDataFactory.createTestAuthSession(user: user, accessToken: "token2")
        
        // Then
        #expect(session1 == session2)
        #expect(session1 != session3)
    }
    
    // MARK: - Golf Round Model Tests
    
    @Test func golfRoundCreation() async throws {
        // Given
        let holes = [
            TestDataFactory.createTestHoleScore(holeNumber: 1, par: 4, strokes: 5),
            TestDataFactory.createTestHoleScore(holeNumber: 2, par: 3, strokes: 3),
            TestDataFactory.createTestHoleScore(holeNumber: 3, par: 5, strokes: 4)
        ]
        
        let round = GolfRound(
            id: "round123",
            userId: "user123",
            courseName: "Test Course",
            date: Date(),
            totalScore: 12,
            par: 12,
            holes: holes,
            notes: "Great round!",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        #expect(round.id == "round123")
        #expect(round.courseName == "Test Course")
        #expect(round.totalScore == 12)
        #expect(round.par == 12)
        #expect(round.holes.count == 3)
        #expect(round.notes == "Great round!")
    }
    
    @Test func golfRoundComputedProperties() async throws {
        // Given
        let round = TestDataFactory.createTestGolfRound(totalScore: 85, par: 72)
        
        // Then
        #expect(round.scoreRelativeToPar == 13) // 85 - 72
        #expect(round.scoreDescription == "+13")
        
        // Test different score scenarios
        let parRound = TestDataFactory.createTestGolfRound(totalScore: 72, par: 72)
        #expect(parRound.scoreRelativeToPar == 0)
        #expect(parRound.scoreDescription == "Par")
        
        let underParRound = TestDataFactory.createTestGolfRound(totalScore: 68, par: 72)
        #expect(underParRound.scoreRelativeToPar == -4)
        #expect(underParRound.scoreDescription == "-4")
    }
    
    // MARK: - Hole Score Model Tests
    
    @Test func holeScoreCreation() async throws {
        // Given
        let hole = TestDataFactory.createTestHoleScore(
            holeNumber: 5,
            par: 4,
            strokes: 3,
            putts: 1,
            fairwayHit: true,
            greenInRegulation: true
        )
        
        // Then
        #expect(hole.holeNumber == 5)
        #expect(hole.par == 4)
        #expect(hole.strokes == 3)
        #expect(hole.putts == 1)
        #expect(hole.fairwayHit == true)
        #expect(hole.greenInRegulation == true)
    }
    
    @Test func holeScoreComputedProperties() async throws {
        // Given
        let birdieHole = TestDataFactory.createTestHoleScore(par: 4, strokes: 3)
        let parHole = TestDataFactory.createTestHoleScore(par: 4, strokes: 4)
        let bogeyHole = TestDataFactory.createTestHoleScore(par: 4, strokes: 5)
        let eagleHole = TestDataFactory.createTestHoleScore(par: 5, strokes: 3)
        let albatrossHole = TestDataFactory.createTestHoleScore(par: 5, strokes: 2)
        let doubleBogeyHole = TestDataFactory.createTestHoleScore(par: 4, strokes: 6)
        
        // Then
        #expect(birdieHole.scoreRelativeToPar == -1)
        #expect(birdieHole.scoreType == .birdie)
        
        #expect(parHole.scoreRelativeToPar == 0)
        #expect(parHole.scoreType == .par)
        
        #expect(bogeyHole.scoreRelativeToPar == 1)
        #expect(bogeyHole.scoreType == .bogey)
        
        #expect(eagleHole.scoreRelativeToPar == -2)
        #expect(eagleHole.scoreType == .eagle)
        
        #expect(albatrossHole.scoreRelativeToPar == -3)
        #expect(albatrossHole.scoreType == .albatross)
        
        #expect(doubleBogeyHole.scoreRelativeToPar == 2)
        #expect(doubleBogeyHole.scoreType == .doubleBogey)
    }
    
    @Test func holeScoreTypeValues() async throws {
        // Test all enum cases
        #expect(HoleScoreType.albatross.rawValue == "Albatross")
        #expect(HoleScoreType.eagle.rawValue == "Eagle")
        #expect(HoleScoreType.birdie.rawValue == "Birdie")
        #expect(HoleScoreType.par.rawValue == "Par")
        #expect(HoleScoreType.bogey.rawValue == "Bogey")
        #expect(HoleScoreType.doubleBogey.rawValue == "Double Bogey")
        #expect(HoleScoreType.other.rawValue == "Other")
        
        // Test case iterable
        #expect(HoleScoreType.allCases.count == 7)
    }
    
    // MARK: - User Golf Stats Tests
    
    @Test func userGolfStatsCreation() async throws {
        // Given
        let stats = TestDataFactory.createTestUserGolfStats(
            totalRounds: 25,
            averageScore: 82.5,
            bestScore: 75,
            worstScore: 95,
            handicapIndex: 12.8
        )
        
        // Then
        #expect(stats.totalRounds == 25)
        #expect(stats.averageScore == 82.5)
        #expect(stats.bestScore == 75)
        #expect(stats.worstScore == 95)
        #expect(stats.handicapIndex == 12.8)
        #expect(stats.totalBirdies == 25)
        #expect(stats.totalEagles == 2)
        #expect(stats.totalPars == 120)
        #expect(stats.totalBogeys == 85)
        #expect(stats.favoriteCourse == "Test Golf Course")
    }
    
    @Test func userGolfStatsValidation() async throws {
        // Given
        let validStats = TestDataFactory.createTestUserGolfStats()
        let invalidStats = UserGolfStats(
            userId: "user123",
            totalRounds: -1,
            averageScore: -50.0,
            bestScore: -10,
            worstScore: -20,
            handicapIndex: nil,
            totalBirdies: 0,
            totalEagles: 0,
            totalPars: 0,
            totalBogeys: 0,
            favoriteCourse: nil,
            lastPlayedDate: nil,
            updatedAt: Date()
        )
        
        // Then
        #expect(TestAssertions.assertValidUserStats(validStats))
        #expect(!TestAssertions.assertValidUserStats(invalidStats))
    }
    
    // MARK: - Golf Course Model Tests
    
    @Test func golfCourseCreation() async throws {
        // Given
        let course = TestDataFactory.createTestGolfCourse(
            name: "Augusta National",
            location: "Augusta, GA",
            par: 72,
            holes: 18
        )
        
        // Then
        #expect(course.name == "Augusta National")
        #expect(course.location == "Augusta, GA")
        #expect(course.par == 72)
        #expect(course.holes == 18)
        #expect(course.rating == 73.2)
        #expect(course.slope == 125)
        #expect(course.description == "A test golf course")
    }
    
    // MARK: - Dashboard Data Model Tests
    
    @Test func dashboardDataCreation() async throws {
        // Given
        let stats = TestDataFactory.createTestUserGolfStats()
        let rounds = [TestDataFactory.createTestGolfRound()]
        
        let dashboardData = DashboardData(
            userStats: stats,
            recentRounds: rounds,
            isLoading: false,
            errorMessage: nil
        )
        
        // Then
        #expect(dashboardData.userStats != nil)
        #expect(dashboardData.recentRounds.count == 1)
        #expect(dashboardData.isLoading == false)
        #expect(dashboardData.errorMessage == nil)
    }
    
    @Test func dashboardDataInitialState() async throws {
        // Given
        let initialData = DashboardData()
        
        // Then
        #expect(initialData.userStats == nil)
        #expect(initialData.recentRounds.isEmpty)
        #expect(initialData.isLoading == false)
        #expect(initialData.errorMessage == nil)
    }
    
    @Test func dashboardDataLoadingState() async throws {
        // Given
        let loadingData = DashboardData(isLoading: true)
        
        // Then
        #expect(loadingData.isLoading == true)
        #expect(loadingData.userStats == nil)
        #expect(loadingData.recentRounds.isEmpty)
    }
    
    @Test func dashboardDataErrorState() async throws {
        // Given
        let errorData = DashboardData(errorMessage: "Network error")
        
        // Then
        #expect(errorData.errorMessage == "Network error")
        #expect(errorData.isLoading == false)
    }
    
    // MARK: - Request/Response Model Tests
    
    @Test func createRoundRequestCreation() async throws {
        // Given
        let holeRequests = [
            CreateHoleScoreRequest(holeNumber: 1, par: 4, strokes: 5, putts: 2, fairwayHit: true, greenInRegulation: false),
            CreateHoleScoreRequest(holeNumber: 2, par: 3, strokes: 3, putts: 2, fairwayHit: nil, greenInRegulation: true)
        ]
        
        let request = CreateRoundRequest(
            courseName: "Test Course",
            date: Date.testDate,
            totalScore: 8,
            par: 7,
            holes: holeRequests,
            notes: "Great round!"
        )
        
        // Then
        #expect(request.courseName == "Test Course")
        #expect(request.totalScore == 8)
        #expect(request.par == 7)
        #expect(request.holes.count == 2)
        #expect(request.notes == "Great round!")
    }
    
    @Test func createHoleScoreRequestCreation() async throws {
        // Given
        let holeRequest = CreateHoleScoreRequest(
            holeNumber: 1,
            par: 4,
            strokes: 3,
            putts: 1,
            fairwayHit: true,
            greenInRegulation: true
        )
        
        // Then
        #expect(holeRequest.holeNumber == 1)
        #expect(holeRequest.par == 4)
        #expect(holeRequest.strokes == 3)
        #expect(holeRequest.putts == 1)
        #expect(holeRequest.fairwayHit == true)
        #expect(holeRequest.greenInRegulation == true)
    }
    
    // MARK: - API Model Tests
    
    @Test func apiScorecardCreation() async throws {
        // Given
        let scorecard = TestDataFactory.createTestAPIScorecard(
            golfCourseId: 123,
            golfCourseName: "API Test Course",
            numberOfHoles: 9
        )
        
        // Then
        #expect(scorecard.golfCourseId == 123)
        #expect(scorecard.golfCourseName == "API Test Course")
        #expect(scorecard.holes.count == 9)
        #expect(scorecard.totalPar > 0)
        #expect(scorecard.totalDistance > 0)
        #expect(scorecard.location == "Test Location")
        #expect(scorecard.country == "Test Country")
    }
    
    @Test func apiScorecardCalculations() async throws {
        // Given
        let holes = [
            APIScorecardHole(holeNumber: 1, par: 4, distanceMeters: 350.0, handicap: 1, score: nil),
            APIScorecardHole(holeNumber: 2, par: 3, distanceMeters: 180.0, handicap: 2, score: nil),
            APIScorecardHole(holeNumber: 3, par: 5, distanceMeters: 520.0, handicap: 3, score: nil)
        ]
        
        let scorecard = APIScorecard(
            golfCourseId: 1,
            golfCourseName: "Test Course",
            location: "Test Location",
            country: "Test Country",
            holes: holes,
            totalPar: holes.reduce(0) { $0 + $1.par },
            totalDistance: holes.reduce(0) { $0 + $1.distanceMeters }
        )
        
        // Then
        #expect(scorecard.totalPar == 12) // 4 + 3 + 5
        #expect(scorecard.totalDistance == 1050.0) // 350 + 180 + 520
    }
    
    // MARK: - Model Coding Tests
    
    @Test func userModelCoding() async throws {
        // Given
        let originalUser = TestDataFactory.createTestUser()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(originalUser)
        let decodedUser = try decoder.decode(User.self, from: data)
        
        // Then
        #expect(decodedUser.id == originalUser.id)
        #expect(decodedUser.email == originalUser.email)
        #expect(decodedUser.name == originalUser.name)
    }
    
    @Test func golfRoundModelCoding() async throws {
        // Given
        let originalRound = TestDataFactory.createTestGolfRound()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(originalRound)
        let decodedRound = try decoder.decode(GolfRound.self, from: data)
        
        // Then
        #expect(decodedRound.id == originalRound.id)
        #expect(decodedRound.courseName == originalRound.courseName)
        #expect(decodedRound.totalScore == originalRound.totalScore)
        #expect(decodedRound.holes.count == originalRound.holes.count)
    }
} 