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
        
        // Validate configuration
        print("🔧 Initializing Supabase client...")
        print("🔗 URL: \(SupabaseConfig.supabaseURL)")
        print("🔑 Key: \(supabaseKey.prefix(20))...")
        
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
            print("✅ Session restored successfully for user: \(session.user.email ?? "unknown")")
        } catch {
            print("❌ Session check failed: \(error)")
            // Clear any existing session if check fails
            self.session = nil
        }
    }
    
    func signUp(email: String, password: String, name: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        print("📝 Attempting to sign up with email: \(email), name: \(name)")
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            if let session = authResponse.session {
                await updateSession(from: session)
                print("✅ Sign up successful for user: \(session.user.email ?? "unknown")")
                isLoading = false
                return true
            } else {
                print("⚠️ Sign up succeeded but no session returned - email confirmation may be required")
                isLoading = false
                // Set a more specific message for email confirmation
                errorMessage = "Registrierung erfolgreich! Bitte überprüfen Sie Ihre E-Mail und bestätigen Sie Ihr Konto."
                return false
            }
        } catch {
            print("❌ Sign up failed: \(error)")
            errorMessage = getUserFriendlyErrorMessage(error)
            isLoading = false
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        print("🔐 Attempting to sign in with email: \(email)")
        print("🔗 Using Supabase URL: \(SupabaseConfig.supabaseURL)")
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Check if email is confirmed
            if session.user.emailConfirmedAt != nil {
                await updateSession(from: session)
                print("✅ Sign in successful for user: \(session.user.email ?? "unknown")")
                isLoading = false
                return true
            } else {
                print("⚠️ Email not confirmed for user: \(session.user.email ?? "unknown")")
                errorMessage = "Bitte bestätigen Sie Ihre E-Mail-Adresse über den Link, den wir Ihnen gesendet haben."
                isLoading = false
                return false
            }
        } catch {
            print("❌ Sign in failed: \(error)")
            errorMessage = getUserFriendlyErrorMessage(error)
            isLoading = false
            return false
        }
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            session = nil
            print("✅ Successfully signed out")
        } catch {
            print("❌ Sign out failed: \(error)")
            errorMessage = getUserFriendlyErrorMessage(error)
        }
    }
    
    func resendConfirmationEmail(email: String) async -> Bool {
        do {
            try await supabase.auth.resend(
                email: email,
                type: .signup
            )
            print("✅ Confirmation email resent to: \(email)")
            return true
        } catch {
            print("❌ Failed to resend confirmation email: \(error)")
            errorMessage = getUserFriendlyErrorMessage(error)
            return false
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
            errorMessage = getUserFriendlyErrorMessage(error)
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
            errorMessage = getUserFriendlyErrorMessage(error)
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
    
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        let errorMessage = error.localizedDescription.lowercased()
        
        // Log the raw error for debugging
        print("🔍 Raw error: \(error)")
        print("🔍 Error description: \(error.localizedDescription)")
        
        if errorMessage.contains("invalid") && (errorMessage.contains("credentials") || errorMessage.contains("login")) {
            return "Ungültige E-Mail oder Passwort. Bitte überprüfen Sie Ihre Eingabe."
        } else if errorMessage.contains("email") && errorMessage.contains("not") && errorMessage.contains("confirmed") {
            return "Bitte bestätigen Sie Ihre E-Mail-Adresse über den Link, den wir Ihnen gesendet haben."
        } else if errorMessage.contains("signup") && errorMessage.contains("disabled") {
            return "Neue Registrierungen sind derzeit deaktiviert. Bitte wenden Sie sich an den Support."
        } else if errorMessage.contains("email") && errorMessage.contains("already") {
            return "Diese E-Mail-Adresse ist bereits registriert. Bitte melden Sie sich an oder verwenden Sie eine andere E-Mail."
        } else if errorMessage.contains("password") && errorMessage.contains("weak") {
            return "Das Passwort ist zu schwach. Bitte verwenden Sie mindestens 6 Zeichen."
        } else if errorMessage.contains("network") || errorMessage.contains("connection") || errorMessage.contains("timeout") {
            return "Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut."
        } else if errorMessage.contains("rate") && errorMessage.contains("limit") {
            return "Zu viele Anmeldeversuche. Bitte warten Sie einen Moment und versuchen Sie es erneut."
        } else if errorMessage.contains("invalid") && errorMessage.contains("email") {
            return "Ungültige E-Mail-Adresse. Bitte überprüfen Sie die Eingabe."
        } else {
            // Include the actual error for debugging purposes
            return "Fehler: \(error.localizedDescription)"
        }
    }
} 
