//
//  ConfigLoader.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation

enum ConfigError: Error {
    case configFileNotFound
    case missingKey(String)
    case invalidConfiguration
}

struct ConfigLoader {
    
    /// Loads configuration from Config.plist file
    /// Falls back to environment variables if Config.plist is not found
    static func loadConfig() throws -> AppConfig {
        
        // Try to load from Config.plist first
        if let config = try? loadFromPlist() {
            return config
        }
        
        // Fallback to environment variables (for CI/CD)
        return try loadFromEnvironment()
    }
    
    private static func loadFromPlist() throws -> AppConfig {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            throw ConfigError.configFileNotFound
        }
        
        guard let supabaseURL = plist["SUPABASE_URL"] as? String,
              let supabaseAnonKey = plist["SUPABASE_ANON_KEY"] as? String,
              let golfAPIBaseURL = plist["GOLF_API_BASE_URL"] as? String else {
            throw ConfigError.invalidConfiguration
        }
        
        let environment = plist["ENVIRONMENT"] as? String ?? "development"
        
        // Validate that we don't have placeholder values
        if supabaseURL.contains("YOUR_") || supabaseAnonKey.contains("YOUR_") {
            throw ConfigError.invalidConfiguration
        }
        
        return AppConfig(
            supabaseURL: supabaseURL,
            supabaseAnonKey: supabaseAnonKey,
            golfAPIBaseURL: golfAPIBaseURL,
            environment: environment
        )
    }
    
    private static func loadFromEnvironment() throws -> AppConfig {
        guard let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] else {
            throw ConfigError.missingKey("Required Supabase configuration not found")
        }
        
        let golfAPIBaseURL = ProcessInfo.processInfo.environment["GOLF_API_BASE_URL"] ?? "https://golftracker-app-service.azurewebsites.net"
        let environment = ProcessInfo.processInfo.environment["ENVIRONMENT"] ?? "development"
        
        return AppConfig(
            supabaseURL: supabaseURL,
            supabaseAnonKey: supabaseAnonKey,
            golfAPIBaseURL: golfAPIBaseURL,
            environment: environment
        )
    }
}

struct AppConfig {
    let supabaseURL: String
    let supabaseAnonKey: String
    let golfAPIBaseURL: String
    let environment: String
    
    var isProduction: Bool {
        return environment.lowercased() == "production"
    }
    
    var isDevelopment: Bool {
        return environment.lowercased() == "development"
    }
} 
