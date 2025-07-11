//
//  BasicRoundTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import XCTest
@testable import GolfTracker

final class BasicRoundTests: XCTestCase {
    
    // MARK: - Golf Round Creation Tests
    
    func testGolfRoundCreation() {
        // Given
        let roundId = "test-round-123"
        let userId = "test-user-456"
        let courseName = "Pebble Beach Golf Links"
        let totalScore = 82
        let par = 72
        
        // When
        let round = TestDataFactory.createTestGolfRound(
            id: roundId,
            userId: userId,
            courseName: courseName,
            totalScore: totalScore,
            par: par
        )
        
        // Then
        XCTAssertEqual(round.id, roundId)
        XCTAssertEqual(round.userId, userId)
        XCTAssertEqual(round.courseName, courseName)
        XCTAssertEqual(round.totalScore, totalScore)
        XCTAssertEqual(round.par, par)
        XCTAssertEqual(round.holes.count, 18) // Default number of holes
        XCTAssertEqual(round.scoreRelativeToPar, 10) // 82 - 72
        XCTAssertEqual(round.scoreDescription, "+10")
    }
    
    func testGolfRoundValidation() {
        // Given
        let validRound = TestDataFactory.createTestGolfRound()
        
        // When & Then
        XCTAssertTrue(TestAssertions.assertValidGolfRound(validRound))
        XCTAssertFalse(validRound.id.isEmpty)
        XCTAssertFalse(validRound.userId.isEmpty)
        XCTAssertFalse(validRound.courseName.isEmpty)
        XCTAssertGreaterThan(validRound.totalScore, 0)
        XCTAssertGreaterThan(validRound.par, 0)
        XCTAssertFalse(validRound.holes.isEmpty)
    }
    
    // MARK: - In-Progress Round Tests
    
    func testInProgressRoundInitialization() {
        // Given
        let courseName = "Augusta National"
        let numberOfHoles = 18
        
        // When
        let round = InProgressRound(courseName: courseName, numberOfHoles: numberOfHoles)
        
        // Then
        XCTAssertEqual(round.courseName, courseName)
        XCTAssertEqual(round.numberOfHoles, numberOfHoles)
        XCTAssertEqual(round.holes.count, numberOfHoles)
        XCTAssertEqual(round.currentHole, 1)
        XCTAssertEqual(round.totalScore, 0)
        XCTAssertEqual(round.completedHoles, 0)
        XCTAssertFalse(round.isCompleted)
        XCTAssertFalse(round.isReadyToFinish)
    }
    
    func testInProgressRoundWithDifferentHoleCounts() {
        // Test 9-hole round
        let nineHoleRound = InProgressRound(numberOfHoles: 9)
        XCTAssertEqual(nineHoleRound.holes.count, 9)
        XCTAssertEqual(nineHoleRound.numberOfHoles, 9)
        
        // Test 18-hole round
        let eighteenHoleRound = InProgressRound(numberOfHoles: 18)
        XCTAssertEqual(eighteenHoleRound.holes.count, 18)
        XCTAssertEqual(eighteenHoleRound.numberOfHoles, 18)
        
        // Test custom hole count
        let customRound = InProgressRound(numberOfHoles: 12)
        XCTAssertEqual(customRound.holes.count, 12)
        XCTAssertEqual(customRound.numberOfHoles, 12)
    }
    
    func testInProgressRoundScoreTracking() {
        // Given
        let round = InProgressRound(courseName: "Test Course", numberOfHoles: 9)
        
        // When - score first few holes
        round.holes[0].strokes = 4 // Par 4
        round.holes[1].strokes = 3 // Par 4 - Birdie
        round.holes[2].strokes = 5 // Par 4 - Bogey
        
        // Then
        XCTAssertEqual(round.totalScore, 12)
        XCTAssertEqual(round.completedHoles, 3)
        XCTAssertEqual(round.scoreRelativeToPar, 12 - round.totalPar)
        XCTAssertFalse(round.isReadyToFinish) // Not all holes completed
        
        // When - complete all holes
        for i in 3..<9 {
            round.holes[i].strokes = 4
        }
        
        // Then
        XCTAssertEqual(round.totalScore, 36)
        XCTAssertEqual(round.completedHoles, 9)
        XCTAssertTrue(round.isReadyToFinish) // All holes completed and has course name
    }
    
    func testInProgressRoundNavigationBetweenHoles() {
        // Given
        let round = InProgressRound(numberOfHoles: 18)
        
        // Test moving to different holes
        round.currentHole = 5
        XCTAssertEqual(round.currentHole, 5)
        
        round.currentHole = 18
        XCTAssertEqual(round.currentHole, 18)
        
        round.currentHole = 1
        XCTAssertEqual(round.currentHole, 1)
    }
    
    // MARK: - Hole Score Tests
    
    func testInProgressHoleScoreInitialization() {
        // Given
        let holeNumber = 7
        let par = 4
        let distance = 385.5
        let handicap = 3
        
        // When
        let hole = InProgressHoleScore(
            holeNumber: holeNumber,
            par: par,
            distanceMeters: distance,
            handicap: handicap
        )
        
        // Then
        XCTAssertEqual(hole.holeNumber, holeNumber)
        XCTAssertEqual(hole.par, par)
        XCTAssertEqual(hole.distanceMeters, distance)
        XCTAssertEqual(hole.handicap, handicap)
        XCTAssertNil(hole.strokes)
        XCTAssertNil(hole.putts)
        XCTAssertNil(hole.fairwayHit)
        XCTAssertNil(hole.greenInRegulation)
        XCTAssertFalse(hole.isCompleted)
        XCTAssertNil(hole.scoreRelativeToPar)
        XCTAssertNil(hole.scoreType)
    }
    
    func testInProgressHoleScoreCompletion() {
        // Given
        var hole = InProgressHoleScore(holeNumber: 1, par: 4)
        
        // When - add score
        hole.strokes = 3
        hole.putts = 1
        hole.fairwayHit = true
        hole.greenInRegulation = true
        
        // Then
        XCTAssertTrue(hole.isCompleted)
        XCTAssertEqual(hole.scoreRelativeToPar, -1)
        XCTAssertEqual(hole.scoreType, .birdie)
    }
    
    func testInProgressHoleScoreTypes() {
        // Test various score types
        var hole = InProgressHoleScore(holeNumber: 1, par: 4)
        
        // Test eagle
        hole.strokes = 2
        XCTAssertEqual(hole.scoreType, .eagle)
        XCTAssertEqual(hole.scoreRelativeToPar, -2)
        
        // Test birdie
        hole.strokes = 3
        XCTAssertEqual(hole.scoreType, .birdie)
        XCTAssertEqual(hole.scoreRelativeToPar, -1)
        
        // Test par
        hole.strokes = 4
        XCTAssertEqual(hole.scoreType, .par)
        XCTAssertEqual(hole.scoreRelativeToPar, 0)
        
        // Test bogey
        hole.strokes = 5
        XCTAssertEqual(hole.scoreType, .bogey)
        XCTAssertEqual(hole.scoreRelativeToPar, 1)
        
        // Test double bogey
        hole.strokes = 6
        XCTAssertEqual(hole.scoreType, .doubleBogey)
        XCTAssertEqual(hole.scoreRelativeToPar, 2)
        
        // Test other
        hole.strokes = 8
        XCTAssertEqual(hole.scoreType, .other)
        XCTAssertEqual(hole.scoreRelativeToPar, 4)
    }
    
    // MARK: - Round Completion Tests
    
    func testRoundReadinessForCompletion() {
        // Given
        let round = InProgressRound(numberOfHoles: 9)
        
        // Initially not ready
        XCTAssertFalse(round.isReadyToFinish)
        
        // Add course name but no scores
        round.courseName = "Test Course"
        XCTAssertFalse(round.isReadyToFinish)
        
        // Complete all holes
        for i in 0..<9 {
            round.holes[i].strokes = 4
        }
        
        // Now should be ready
        XCTAssertTrue(round.isReadyToFinish)
        
        // Remove course name
        round.courseName = ""
        XCTAssertFalse(round.isReadyToFinish)
    }
    
    func testRoundWithAPIScorecard() {
        // Given
        let round = InProgressRound(numberOfHoles: 18)
        let apiScorecard = TestDataFactory.createTestAPIScorecard()
        
        // When
        round.setupFromScorecard(apiScorecard)
        
        // Then
        XCTAssertNotNil(round.apiScorecard)
        XCTAssertEqual(round.apiScorecard?.golfCourseName, apiScorecard.golfCourseName)
        XCTAssertEqual(round.courseName, apiScorecard.golfCourseName)
        XCTAssertEqual(round.courseLocation, "\(apiScorecard.location), \(apiScorecard.country)")
        XCTAssertEqual(round.courseId, apiScorecard.golfCourseId)
        XCTAssertEqual(round.numberOfHoles, apiScorecard.holes.count)
        XCTAssertEqual(round.holes.count, apiScorecard.holes.count)
        
        // Verify hole details are set from API data
        for (index, apiHole) in apiScorecard.holes.enumerated() {
            let roundHole = round.holes[index]
            XCTAssertEqual(roundHole.par, apiHole.par)
            XCTAssertEqual(roundHole.distanceMeters, apiHole.distanceMeters)
            XCTAssertEqual(roundHole.handicap, apiHole.handicap)
        }
    }
    
    // MARK: - Round Statistics Tests
    
    func testRoundStatisticsCalculation() {
        // Given
        let round = TestDataFactory.createTestInProgressRound(numberOfHoles: 9)
        
        // Score holes with variety of results
        round.holes[0].strokes = 3 // Birdie on par 4
        round.holes[1].strokes = 3 // Par on par 3
        round.holes[2].strokes = 4 // Par on par 4
        round.holes[3].strokes = 5 // Bogey on par 4
        round.holes[4].strokes = 6 // Double bogey on par 4
        round.holes[5].strokes = 4 // Par on par 4
        round.holes[6].strokes = 3 // Birdie on par 4
        round.holes[7].strokes = 2 // Eagle on par 4
        round.holes[8].strokes = 5 // Par on par 5
        
        // When
        let totalScore = round.totalScore
        let totalPar = round.totalPar
        let scoreRelativeToPar = round.scoreRelativeToPar
        let completedHoles = round.completedHoles
        
        // Then
        XCTAssertEqual(totalScore, 35) // Sum of all strokes
        XCTAssertEqual(completedHoles, 9)
        XCTAssertEqual(scoreRelativeToPar, totalScore - totalPar)
    }
} 