//
//  SupabaseAuthService.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation
import Supabase

@MainActor
class SupabaseAuthService: ObservableObject {
    @Published var session: AuthSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase: SupabaseClient
    
    init() {
        // Use configuration from SupabaseConfig
        guard let supabaseURL = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL configuration")
        }
        let supabaseKey = SupabaseConfig.supabaseAnonKey
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        // Check for existing session on init
        Task {
            await checkSession()
        }
    }
    
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            await updateSession(from: session)
        } catch {
            print("Session check failed: \(error)")
        }
    }
    
    func signUp(email: String, password: String, name: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            if let session = authResponse.session {
                await updateSession(from: session)
                isLoading = false
                return true
            }
            
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await updateSession(from: session)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            session = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signInWithGoogle() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.signInWithOAuth(provider: .google)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signInWithGitHub() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.signInWithOAuth(provider: .github)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    private func updateSession(from supabaseSession: Session) async {
        let user = User(
            id: supabaseSession.user.id.uuidString,
            email: supabaseSession.user.email ?? "",
            name: supabaseSession.user.userMetadata["name"]?.stringValue,
            createdAt: supabaseSession.user.createdAt
        )
        
        self.session = AuthSession(
            user: user,
            accessToken: supabaseSession.accessToken,
            refreshToken: supabaseSession.refreshToken
        )
    }
} 