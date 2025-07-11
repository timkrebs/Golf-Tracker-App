//
//  TestHelpers.swift
//  GolfTrackerTests
//
//  Created by Tim Krebs on 7/11/25.
//

import Foundation
@testable import GolfTracker

// MARK: - Test Data Factory

struct TestDataFactory {
    
    // MARK: - User Test Data
    
    static func createTestUser(
        id: String = "test-user-123",
        email: String = "test@example.com",
        name: String = "Test User"
    ) -> User {
        return User(
            id: id,
            email: email,
            name: name,
            createdAt: Date()
        )
    }
    
    static func createTestAuthSession(
        user: User = createTestUser(),
        accessToken: String = "test-access-token",
        refreshToken: String = "test-refresh-token"
    ) -> AuthSession {
        return AuthSession(
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
    
    // MARK: - Golf Round Test Data
    
    static func createTestGolfRound(
        id: String = "test-round-123",
        userId: String = "test-user-123",
        courseName: String = "Test Golf Course",
        totalScore: Int = 85,
        par: Int = 72,
        numberOfHoles: Int = 18
    ) -> GolfRound {
        let holes = (1...numberOfHoles).map { holeNumber in
            createTestHoleScore(
                roundId: id,
                holeNumber: holeNumber,
                par: holeNumber <= 4 ? 4 : (holeNumber <= 14 ? 3 : 5),
                strokes: Int.random(in: 3...7)
            )
        }
        
        return GolfRound(
            id: id,
            userId: userId,
            courseName: courseName,
            date: Date(),
            totalScore: totalScore,
            par: par,
            holes: holes,
            notes: "Test round notes",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func createTestHoleScore(
        id: String = UUID().uuidString,
        roundId: String = "test-round-123",
        holeNumber: Int = 1,
        par: Int = 4,
        strokes: Int = 4,
        putts: Int? = 2,
        fairwayHit: Bool? = true,
        greenInRegulation: Bool? = true
    ) -> HoleScore {
        return HoleScore(
            id: id,
            roundId: roundId,
            holeNumber: holeNumber,
            par: par,
            strokes: strokes,
            putts: putts,
            fairwayHit: fairwayHit,
            greenInRegulation: greenInRegulation
        )
    }
    
    // MARK: - Statistics Test Data
    
    static func createTestUserGolfStats(
        userId: String = "test-user-123",
        totalRounds: Int = 10,
        averageScore: Double = 85.5,
        bestScore: Int = 78,
        worstScore: Int = 95,
        handicapIndex: Double = 15.2
    ) -> UserGolfStats {
        return UserGolfStats(
            userId: userId,
            totalRounds: totalRounds,
            averageScore: averageScore,
            bestScore: bestScore,
            worstScore: worstScore,
            handicapIndex: handicapIndex,
            totalBirdies: 25,
            totalEagles: 2,
            totalPars: 120,
            totalBogeys: 85,
            favoriteCourse: "Test Golf Course",
            lastPlayedDate: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Course Test Data
    
    static func createTestGolfCourse(
        id: String = "test-course-123",
        name: String = "Test Golf Course",
        location: String = "Test Location",
        par: Int = 72,
        holes: Int = 18
    ) -> GolfCourse {
        return GolfCourse(
            id: id,
            name: name,
            location: location,
            par: par,
            holes: holes,
            rating: 73.2,
            slope: 125,
            description: "A test golf course"
        )
    }
    
    // MARK: - API Test Data
    
    static func createTestAPIScorecard(
        golfCourseId: Int = 1,
        golfCourseName: String = "Test API Course",
        location: String = "Test Location",
        numberOfHoles: Int = 18
    ) -> APIScorecard {
        let holes = (1...numberOfHoles).map { holeNumber in
            APIScorecardHole(
                holeNumber: holeNumber,
                par: holeNumber <= 4 ? 4 : (holeNumber <= 14 ? 3 : 5),
                distanceMeters: Double.random(in: 150...500),
                handicap: holeNumber,
                score: nil
            )
        }
        
        return APIScorecard(
            golfCourseId: golfCourseId,
            golfCourseName: golfCourseName,
            location: location,
            country: "Test Country",
            holes: holes,
            totalPar: holes.reduce(0) { $0 + $1.par },
            totalDistance: holes.reduce(0) { $0 + $1.distanceMeters }
        )
    }
    
    // MARK: - InProgress Round Test Data
    
    static func createTestInProgressRound(
        courseName: String = "Test Course",
        numberOfHoles: Int = 18
    ) -> InProgressRound {
        let round = InProgressRound(courseName: courseName, numberOfHoles: numberOfHoles)
        
        // Fill some holes with sample scores
        for i in 0..<min(5, numberOfHoles) {
            round.holes[i].strokes = Int.random(in: 3...6)
            round.holes[i].putts = Int.random(in: 1...3)
        }
        
        return round
    }
}

// MARK: - Mock Config for Testing

struct MockAppConfig {
    static let testConfig = AppConfig(
        supabaseURL: "https://test.supabase.co",
        supabaseAnonKey: "test-anon-key-123",
        golfAPIBaseURL: "https://test-api.com",
        environment: "testing"
    )
}

// MARK: - Test Extensions

extension Date {
    static var testDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: "2024-01-15") ?? Date()
    }
    
    static var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }
    
    static var lastWeek: Date {
        Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    }
}

extension HoleScoreType {
    var testScore: Int {
        switch self {
        case .albatross: return 2  // Par 5 -> 2 strokes
        case .eagle: return 3      // Par 5 -> 3 strokes
        case .birdie: return 3     // Par 4 -> 3 strokes
        case .par: return 4        // Par 4 -> 4 strokes
        case .bogey: return 5      // Par 4 -> 5 strokes
        case .doubleBogey: return 6 // Par 4 -> 6 strokes
        case .other: return 7      // Par 4 -> 7 strokes
        }
    }
}

// MARK: - Test Assertions

struct TestAssertions {
    
    static func assertValidGolfRound(_ round: GolfRound) -> Bool {
        guard !round.id.isEmpty,
              !round.userId.isEmpty,
              !round.courseName.isEmpty,
              round.totalScore > 0,
              round.par > 0,
              !round.holes.isEmpty else {
            return false
        }
        
        // Verify hole scores add up to total
        let calculatedTotal = round.holes.reduce(0) { $0 + $1.strokes }
        return calculatedTotal == round.totalScore
    }
    
    static func assertValidHoleScore(_ hole: HoleScore) -> Bool {
        return hole.holeNumber > 0 &&
               hole.par > 0 &&
               hole.strokes > 0 &&
               hole.holeNumber <= 18
    }
    
    static func assertValidUserStats(_ stats: UserGolfStats) -> Bool {
        return stats.totalRounds >= 0 &&
               (stats.averageScore == nil || stats.averageScore! > 0) &&
               (stats.bestScore == nil || stats.bestScore! > 0) &&
               (stats.worstScore == nil || stats.worstScore! > 0)
    }
} 