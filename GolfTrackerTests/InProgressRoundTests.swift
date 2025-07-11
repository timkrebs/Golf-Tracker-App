//
//  InProgressRoundTests.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Testing
import Foundation
@testable import GolfTracker

struct InProgressRoundTests {
    
    // MARK: - Initialization Tests
    
    @Test func inProgressRoundInitialization() async throws {
        // Given & When
        let round = InProgressRound(courseName: "Test Course", numberOfHoles: 18)
        
        // Then
        #expect(round.courseName == "Test Course")
        #expect(round.numberOfHoles == 18)
        #expect(round.holes.count == 18)
        #expect(round.currentHole == 1)
        #expect(round.isCompleted == false)
        #expect(round.notes.isEmpty)
        #expect(round.courseId == nil)
        #expect(round.apiScorecard == nil)
    }
    
    @Test func inProgressRoundDefaultInitialization() async throws {
        // Given & When
        let round = InProgressRound()
        
        // Then
        #expect(round.courseName.isEmpty)
        #expect(round.numberOfHoles == 18)
        #expect(round.holes.count == 18)
        #expect(round.currentHole == 1)
    }
    
    @Test func inProgressRound9HoleInitialization() async throws {
        // Given & When
        let round = InProgressRound(courseName: "9-Hole Course", numberOfHoles: 9)
        
        // Then
        #expect(round.numberOfHoles == 9)
        #expect(round.holes.count == 9)
        #expect(round.courseName == "9-Hole Course")
    }
    
    // MARK: - Hole Management Tests
    
    @Test func numberOfHolesChange() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 18)
        
        // When
        round.numberOfHoles = 9
        
        // Then
        #expect(round.numberOfHoles == 9)
        #expect(round.holes.count == 9)
    }
    
    @Test func numberOfHolesChangeWithCurrentHoleAdjustment() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 18)
        round.currentHole = 15
        
        // When
        round.numberOfHoles = 9
        
        // Then
        #expect(round.numberOfHoles == 9)
        #expect(round.currentHole == 1) // Should reset to first hole
    }
    
    @Test func numberOfHolesChangePreservesCurrentHole() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 9)
        round.currentHole = 5
        
        // When
        round.numberOfHoles = 18
        
        // Then
        #expect(round.numberOfHoles == 18)
        #expect(round.currentHole == 5) // Should preserve current hole
    }
    
    // MARK: - Score Tracking Tests
    
    @Test func addScoreToHole() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 18)
        
        // When
        round.holes[0].strokes = 4
        round.holes[0].putts = 2
        round.holes[1].strokes = 3
        round.holes[1].putts = 1
        
        // Then
        #expect(round.holes[0].strokes == 4)
        #expect(round.holes[0].putts == 2)
        #expect(round.holes[1].strokes == 3)
        #expect(round.holes[1].putts == 1)
    }
    
    @Test func totalParCalculation() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 3)
        round.holes[0].par = 4
        round.holes[1].par = 3
        round.holes[2].par = 5
        
        // When
        let totalPar = round.totalPar
        
        // Then
        #expect(totalPar == 12) // 4 + 3 + 5
    }
    
    @Test func totalScoreCalculation() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 3)
        round.holes[0].strokes = 5
        round.holes[1].strokes = 3
        round.holes[2].strokes = 6
        
        // When
        let totalScore = round.totalScore
        
        // Then
        #expect(totalScore == 14) // 5 + 3 + 6
    }
    
    @Test func totalScoreWithPartialRound() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 3)
        round.holes[0].strokes = 4
        round.holes[1].strokes = 3
        // holes[2].strokes remains nil
        
        // When
        let totalScore = round.totalScore
        
        // Then
        #expect(totalScore == 7) // 4 + 3 + 0 (nil strokes count as 0)
    }
    
    @Test func scoreRelativeToParCalculation() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 3)
        round.holes[0].par = 4
        round.holes[0].strokes = 5
        round.holes[1].par = 3
        round.holes[1].strokes = 3
        round.holes[2].par = 5
        round.holes[2].strokes = 4
        
        // When
        let relativeScore = round.scoreRelativeToPar
        
        // Then
        #expect(round.totalPar == 12)
        #expect(round.totalScore == 12)
        #expect(relativeScore == 0) // Even par
    }
    
    // MARK: - Progress Tracking Tests
    
    @Test func completedHolesCount() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 5)
        round.holes[0].strokes = 4
        round.holes[1].strokes = 3
        round.holes[2].strokes = 5
        // holes[3] and holes[4] have no strokes
        
        // When
        let completedHoles = round.completedHoles
        
        // Then
        #expect(completedHoles == 3)
    }
    
    @Test func isReadyToFinishWithCompletedRound() async throws {
        // Given
        let round = InProgressRound(courseName: "Test Course", numberOfHoles: 3)
        round.holes[0].strokes = 4
        round.holes[1].strokes = 3
        round.holes[2].strokes = 5
        
        // When
        let isReady = round.isReadyToFinish
        
        // Then
        #expect(isReady == true)
    }
    
    @Test func isReadyToFinishWithIncompleteRound() async throws {
        // Given
        let round = InProgressRound(courseName: "Test Course", numberOfHoles: 3)
        round.holes[0].strokes = 4
        round.holes[1].strokes = 3
        // holes[2] has no strokes
        
        // When
        let isReady = round.isReadyToFinish
        
        // Then
        #expect(isReady == false)
    }
    
    @Test func isReadyToFinishWithoutCourseName() async throws {
        // Given
        let round = InProgressRound(courseName: "", numberOfHoles: 3)
        round.holes[0].strokes = 4
        round.holes[1].strokes = 3
        round.holes[2].strokes = 5
        
        // When
        let isReady = round.isReadyToFinish
        
        // Then
        #expect(isReady == false) // Course name is required
    }
    
    // MARK: - API Scorecard Integration Tests
    
    @Test func setAPIScorecard() async throws {
        // Given
        let round = InProgressRound()
        let scorecard = TestDataFactory.createTestAPIScorecard(numberOfHoles: 9)
        
        // When
        round.apiScorecard = scorecard
        
        // Then
        #expect(round.apiScorecard != nil)
        #expect(round.apiScorecard?.holes.count == 9)
        #expect(round.apiScorecard?.golfCourseName == "Test API Course")
    }
    
    @Test func numberOfHolesChangeWithAPIScorecard() async throws {
        // Given
        let round = InProgressRound()
        let scorecard = TestDataFactory.createTestAPIScorecard(numberOfHoles: 9)
        round.apiScorecard = scorecard
        
        // When - Change numberOfHoles when apiScorecard is set
        round.numberOfHoles = 18
        
        // Then - Should not reset holes when apiScorecard is present
        #expect(round.numberOfHoles == 18)
        #expect(round.holes.count == 18)
        #expect(round.apiScorecard != nil) // Should preserve scorecard
    }
    
    // MARK: - Navigation Tests
    
    @Test func currentHoleNavigation() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 18)
        
        // When & Then
        #expect(round.currentHole == 1)
        
        round.currentHole = 5
        #expect(round.currentHole == 5)
        
        round.currentHole = 18
        #expect(round.currentHole == 18)
    }
    
    // MARK: - Helper Method Tests
    
    @Test func setupHolesMethod() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 3)
        
        // Then
        #expect(round.holes.count == 3)
        #expect(round.holes[0].holeNumber == 1)
        #expect(round.holes[1].holeNumber == 2)
        #expect(round.holes[2].holeNumber == 3)
        
        // Default par values should be set
        #expect(round.holes[0].par == 4)
        #expect(round.holes[1].par == 4)
        #expect(round.holes[2].par == 4)
    }
    
    @Test func clearRoundData() async throws {
        // Given
        let round = InProgressRound(courseName: "Test Course", numberOfHoles: 3)
        round.holes[0].strokes = 4
        round.holes[1].strokes = 3
        round.notes = "Great round!"
        round.currentHole = 3
        
        // When - Reset round
        round.courseName = ""
        round.notes = ""
        round.currentHole = 1
        for i in 0..<round.holes.count {
            round.holes[i].strokes = nil
            round.holes[i].putts = nil
        }
        
        // Then
        #expect(round.courseName.isEmpty)
        #expect(round.notes.isEmpty)
        #expect(round.currentHole == 1)
        #expect(round.completedHoles == 0)
        #expect(round.totalScore == 0)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func zeroHolesCourse() async throws {
        // Given & When
        let round = InProgressRound(numberOfHoles: 0)
        
        // Then
        #expect(round.numberOfHoles == 0)
        #expect(round.holes.isEmpty)
        #expect(round.totalPar == 0)
        #expect(round.totalScore == 0)
        #expect(round.completedHoles == 0)
    }
    
    @Test func negativeStrokesHandling() async throws {
        // Given
        let round = InProgressRound(numberOfHoles: 1)
        
        // When - This shouldn't happen in real usage, but test edge case
        round.holes[0].strokes = -1
        
        // Then
        #expect(round.totalScore == -1) // Should handle negative values
    }
    
    @Test func veryLargeNumberOfHoles() async throws {
        // Given & When
        let round = InProgressRound(numberOfHoles: 36) // 36-hole tournament
        
        // Then
        #expect(round.numberOfHoles == 36)
        #expect(round.holes.count == 36)
        #expect(round.holes.last?.holeNumber == 36)
    }
} 