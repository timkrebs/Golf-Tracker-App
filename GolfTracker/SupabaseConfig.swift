//
//  SupabaseConfig.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation

struct SupabaseConfig {
    // MARK: - Supabase Configuration
    // Configuration is now loaded securely from Config.plist or environment variables
    
    private static var config: AppConfig? = {
        do {
            return try ConfigLoader.loadConfig()
        } catch {
            print("❌ Failed to load configuration: \(error)")
            return nil
        }
    }()
    
    /// Your Supabase project URL
    static var supabaseURL: String {
        guard let config = config else {
            fatalError("❌ Supabase configuration not found. Please create Config.plist from Config.plist.template")
        }
        return config.supabaseURL
    }
    
    /// Your Supabase anon public key
    static var supabaseAnonKey: String {
        guard let config = config else {
            fatalError("❌ Supabase configuration not found. Please create Config.plist from Config.plist.template")
        }
        return config.supabaseAnonKey
    }
    
    // MARK: - Setup Instructions
    /*
     To set up Supabase for this project:
     
     1. Create a Supabase Project:
        - Go to https://supabase.com
        - Create a new project
        - Note your project URL and anon key
     
     2. Add Supabase Swift SDK:
        - In Xcode, go to File > Add Package Dependencies
        - Add: https://github.com/supabase/supabase-swift
        - Select the latest version
     
     3. Configure Authentication:
        - In your Supabase dashboard, go to Authentication > Settings
        - Configure providers (Email, Google, GitHub, etc.)
        - Set up redirect URLs for OAuth providers
     
     4. Update Configuration:
        - Replace YOUR_SUPABASE_URL_HERE with your project URL
        - Replace YOUR_SUPABASE_ANON_KEY_HERE with your anon key
     
     5. Database Schema (Optional):
        - The app uses Supabase Auth's built-in user management
        - You can extend with custom tables for golf rounds, scores, etc.
     
     6. OAuth Configuration (Optional):
        - For Google OAuth: Configure in Google Cloud Console
        - For GitHub OAuth: Configure in GitHub Developer Settings
        - Add redirect URLs in Supabase Auth settings
     */
} 
