//
//  RegistrationView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Green gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.4),
                    Color(red: 0.15, green: 0.7, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    // Header Section
                    VStack(spacing: 12) {
                        // Golf Flag Icon
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "flag.fill")
                                .font(.system(size: 25))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                        
                        VStack(spacing: 4) {
                            Text("Golf Tracker")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Verfolgen Sie Ihre Golf-Runden und verbessern Sie Ihr Spiel")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 15)
                    
                    // Registration Form Card
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Registrieren")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Erstellen Sie ein Konto, um Ihre Golf-Runden zu verfolgen")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 12) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                        .frame(width: 18)
                                    
                                    TextField("Ihr Name", text: $name)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 15))
                                        .autocapitalization(.words)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("E-Mail")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                        .frame(width: 18)
                                    
                                    TextField("ihre.email@example.com", text: $email)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 15))
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Passwort")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                        .frame(width: 18)
                                    
                                    if showPassword {
                                        TextField("Mindestens 6 Zeichen", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(.system(size: 15))
                                    } else {
                                        SecureField("Mindestens 6 Zeichen", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(.system(size: 15))
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        
                        // Register Button
                        Button(action: {
                            Task {
                                await signUp()
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text("Registrieren")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .cornerRadius(10)
                        }
                        .disabled(authService.isLoading || name.isEmpty || email.isEmpty || password.count < 6)
                        
                        // OAuth Divider
                        VStack(spacing: 10) {
                            Text("ODER REGISTRIEREN MIT")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                                .tracking(0.5)
                            
                            HStack(spacing: 10) {
                                // Google Sign Up
                                Button(action: {
                                    Task {
                                        await authService.signInWithGoogle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "globe")
                                        Text("Google")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                }
                                
                                // GitHub Sign Up
                                Button(action: {
                                    Task {
                                        await authService.signInWithGitHub()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "swift")
                                        Text("GitHub")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Login Link
                        HStack {
                            Text("Bereits registriert?")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Button("Anmelden") {
                                dismiss()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 25)
            }
        }
        .alert("Registration Error", isPresented: .constant(authService.errorMessage != nil)) {
            Button("OK") {
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "")
        }
    }
    
    private func signUp() async {
        let success = await authService.signUp(email: email, password: password, name: name)
        if success {
            dismiss()
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(SupabaseAuthService())
} 