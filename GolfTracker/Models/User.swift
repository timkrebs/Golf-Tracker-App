//
//  User.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let name: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.name == rhs.name
    }
}

struct AuthSession: Equatable {
    let user: User
    let accessToken: String
    let refreshToken: String
    
    static func == (lhs: AuthSession, rhs: AuthSession) -> Bool {
        return lhs.user.id == rhs.user.id &&
               lhs.accessToken == rhs.accessToken &&
               lhs.refreshToken == rhs.refreshToken
    }
} 