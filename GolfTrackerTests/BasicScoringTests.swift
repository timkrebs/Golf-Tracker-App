//
//  BasicScoringTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import XCTest
@testable import GolfTracker

final class BasicScoringTests: XCTestCase {
    
    // MARK: - Golf Round Scoring Tests
    
    func testGolfRoundScoreRelativeToPar() {
        // Test under par
        let underParRound = TestDataFactory.createTestGolfRound(
            totalScore: 68,
            par: 72
        )
        XCTAssertEqual(underParRound.scoreRelativeToPar, -4)
        XCTAssertEqual(underParRound.scoreDescription, "-4")
        
        // Test par
        let parRound = TestDataFactory.createTestGolfRound(
            totalScore: 72,
            par: 72
        )
        XCTAssertEqual(parRound.scoreRelativeToPar, 0)
        XCTAssertEqual(parRound.scoreDescription, "Par")
        
        // Test over par
        let overParRound = TestDataFactory.createTestGolfRound(
            totalScore: 85,
            par: 72
        )
        XCTAssertEqual(overParRound.scoreRelativeToPar, 13)
        XCTAssertEqual(overParRound.scoreDescription, "+13")
    }
    
    // MARK: - Hole Score Tests
    
    func testHoleScoreTypes() {
        // Test albatross (3 under par)
        let albatross = TestDataFactory.createTestHoleScore(
            par: 5,
            strokes: 2
        )
        XCTAssertEqual(albatross.scoreRelativeToPar, -3)
        XCTAssertEqual(albatross.scoreType, .albatross)
        
        // Test eagle (2 under par)
        let eagle = TestDataFactory.createTestHoleScore(
            par: 5,
            strokes: 3
        )
        XCTAssertEqual(eagle.scoreRelativeToPar, -2)
        XCTAssertEqual(eagle.scoreType, .eagle)
        
        // Test birdie (1 under par)
        let birdie = TestDataFactory.createTestHoleScore(
            par: 4,
            strokes: 3
        )
        XCTAssertEqual(birdie.scoreRelativeToPar, -1)
        XCTAssertEqual(birdie.scoreType, .birdie)
        
        // Test par
        let par = TestDataFactory.createTestHoleScore(
            par: 4,
            strokes: 4
        )
        XCTAssertEqual(par.scoreRelativeToPar, 0)
        XCTAssertEqual(par.scoreType, .par)
        
        // Test bogey (1 over par)
        let bogey = TestDataFactory.createTestHoleScore(
            par: 4,
            strokes: 5
        )
        XCTAssertEqual(bogey.scoreRelativeToPar, 1)
        XCTAssertEqual(bogey.scoreType, .bogey)
        
        // Test double bogey (2 over par)
        let doubleBogey = TestDataFactory.createTestHoleScore(
            par: 4,
            strokes: 6
        )
        XCTAssertEqual(doubleBogey.scoreRelativeToPar, 2)
        XCTAssertEqual(doubleBogey.scoreType, .doubleBogey)
        
        // Test other (3+ over par)
        let other = TestDataFactory.createTestHoleScore(
            par: 4,
            strokes: 8
        )
        XCTAssertEqual(other.scoreRelativeToPar, 4)
        XCTAssertEqual(other.scoreType, .other)
    }
    
    // MARK: - InProgress Round Scoring Tests
    
    func testInProgressRoundScoring() {
        // Create a simple round directly instead of using the factory
        let round = InProgressRound(courseName: "Test Course", numberOfHoles: 9)
        
        // Test initial state
        XCTAssertEqual(round.totalScore, 0)
        XCTAssertEqual(round.completedHoles, 0)
        XCTAssertFalse(round.isReadyToFinish)
        
        // Add scores to first 3 holes
        round.holes[0].strokes = 4 // Par
        round.holes[1].strokes = 3 // Birdie
        round.holes[2].strokes = 5 // Bogey
        
        XCTAssertEqual(round.totalScore, 12)
        XCTAssertEqual(round.completedHoles, 3)
        XCTAssertFalse(round.isReadyToFinish) // Not all holes completed
        
        // Complete all holes
        for i in 3..<9 {
            round.holes[i].strokes = 4
        }
        
        XCTAssertEqual(round.totalScore, 36)
        XCTAssertEqual(round.completedHoles, 9)
        XCTAssertTrue(round.isReadyToFinish)
    }
    
    func testInProgressRoundParCalculation() {
        let round = InProgressRound(numberOfHoles: 18)
        
        // Set realistic par values
        for i in 0..<18 {
            if i < 4 || i >= 14 { // First 4 and last 4 holes are par 5
                round.holes[i].par = 5
            } else if i < 10 { // Holes 5-10 are par 3
                round.holes[i].par = 3
            } else { // Holes 11-14 are par 4
                round.holes[i].par = 4
            }
        }
        
        let expectedPar = (8 * 5) + (6 * 3) + (4 * 4) // 40 + 18 + 16 = 74
        XCTAssertEqual(round.totalPar, expectedPar)
    }
    
    // MARK: - Score Validation Tests
    
    func testValidScoreRanges() {
        // Test typical golf scores
        let validScores = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        
        for score in validScores {
            let hole = TestDataFactory.createTestHoleScore(
                par: 4,
                strokes: score
            )
            XCTAssertGreaterThan(hole.strokes, 0)
            XCTAssertLessThanOrEqual(hole.strokes, 15) // Reasonable upper limit
        }
    }
    
    func testScoreEdgeCases() {
        // Test hole-in-one on par 4
        let holeInOne = TestDataFactory.createTestHoleScore(
            par: 4,
            strokes: 1
        )
        XCTAssertEqual(holeInOne.scoreType, .albatross)
        XCTAssertEqual(holeInOne.scoreRelativeToPar, -3)
        
        // Test maximum reasonable score
        let maxScore = TestDataFactory.createTestHoleScore(
            par: 4,
            strokes: 10
        )
        XCTAssertEqual(maxScore.scoreType, .other)
        XCTAssertEqual(maxScore.scoreRelativeToPar, 6)
    }
} 