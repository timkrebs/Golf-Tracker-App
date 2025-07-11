//
//  GolfModels.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation

// MARK: - Golf Round Models

struct GolfRound: Identifiable, Codable {
    let id: String
    let userId: String
    let courseName: String
    let date: Date
    let totalScore: Int
    let par: Int
    let holes: [HoleScore]
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties
    var scoreRelativeToPar: Int {
        totalScore - par
    }
    
    var scoreDescription: String {
        let relative = scoreRelativeToPar
        if relative == 0 { 
            return "Par" 
        } else if relative > 0 { 
            return "+\(relative)" 
        } else { 
            return "\(relative)" 
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, par, notes
        case userId = "user_id"
        case courseName = "course_name"
        case date
        case totalScore = "total_score"
        case holes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct HoleScore: Identifiable, Codable {
    let id: String
    let roundId: String
    let holeNumber: Int
    let par: Int
    let strokes: Int
    let putts: Int?
    let fairwayHit: Bool?
    let greenInRegulation: Bool?
    
    // Computed properties
    var scoreRelativeToPar: Int {
        strokes - par
    }
    
    var scoreType: HoleScoreType {
        let relative = scoreRelativeToPar
        switch relative {
        case ...(-3): return .albatross
        case -2: return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        case 2: return .doubleBogey
        default: return .other
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, par, strokes, putts
        case roundId = "round_id"
        case holeNumber = "hole_number"
        case fairwayHit = "fairway_hit"
        case greenInRegulation = "green_in_regulation"
    }
}

enum HoleScoreType: String, CaseIterable {
    case albatross = "Albatross"
    case eagle = "Eagle"
    case birdie = "Birdie"
    case par = "Par"
    case bogey = "Bogey"
    case doubleBogey = "Double Bogey"
    case other = "Other"
}

// MARK: - User Golf Statistics

struct UserGolfStats: Codable {
    let userId: String
    let totalRounds: Int
    let averageScore: Double?
    let bestScore: Int?
    let worstScore: Int?
    let handicapIndex: Double?
    let totalBirdies: Int
    let totalEagles: Int
    let totalPars: Int
    let totalBogeys: Int
    let favoriteCourse: String?
    let lastPlayedDate: Date?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case totalRounds = "total_rounds"
        case averageScore = "average_score"
        case bestScore = "best_score"
        case worstScore = "worst_score"
        case handicapIndex = "handicap_index"
        case totalBirdies = "total_birdies"
        case totalEagles = "total_eagles"
        case totalPars = "total_pars"
        case totalBogeys = "total_bogeys"
        case favoriteCourse = "favorite_course"
        case lastPlayedDate = "last_played_date"
        case userId = "user_id"
        case updatedAt = "updated_at"
    }
}

// MARK: - Course Models

struct GolfCourse: Identifiable, Codable {
    let id: String
    let name: String
    let location: String?
    let par: Int
    let holes: Int
    let rating: Double?
    let slope: Int?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, par, holes, rating, slope, description
    }
}

// MARK: - Dashboard Data Model

struct DashboardData {
    let userStats: UserGolfStats?
    let recentRounds: [GolfRound]
    let isLoading: Bool
    let errorMessage: String?
    
    init(userStats: UserGolfStats? = nil, recentRounds: [GolfRound] = [], isLoading: Bool = false, errorMessage: String? = nil) {
        self.userStats = userStats
        self.recentRounds = recentRounds
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
}

// MARK: - Request/Response Models

struct CreateRoundRequest: Codable {
    let courseName: String
    let date: Date
    let totalScore: Int
    let par: Int
    let holes: [CreateHoleScoreRequest]
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case courseName = "course_name"
        case date
        case totalScore = "total_score"
        case par
        case holes
        case notes
    }
}

struct CreateHoleScoreRequest: Codable {
    let holeNumber: Int
    let par: Int
    let strokes: Int
    let putts: Int?
    let fairwayHit: Bool?
    let greenInRegulation: Bool?
    
    enum CodingKeys: String, CodingKey {
        case holeNumber = "hole_number"
        case par
        case strokes
        case putts
        case fairwayHit = "fairway_hit"
        case greenInRegulation = "green_in_regulation"
    }
} 
