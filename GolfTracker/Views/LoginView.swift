//
//  LoginView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showRegistration = false
    
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
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Golf Flag Icon
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "flag.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                        
                        VStack(spacing: 6) {
                            Text("Golf Tracker")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Verfolgen Sie Ihre Golf-Runden und verbessern Sie Ihr Spiel")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Login Form Card
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Text("Anmelden")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Melden Sie sich an, um Ihre Golf-Runden zu verfolgen")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("E-Mail")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    TextField("Mail", text: $email)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.system(size: 16))
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Passwort")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    if showPassword {
                                        TextField("Passwort", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(.system(size: 16))
                                    } else {
                                        SecureField("Passwort", text: $password)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(.system(size: 16))
                                    }
                                    
                                    Button(action: { showPassword.toggle() }, label: {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    })
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Login Button
                        Button(action: {
                            Task {
                                await signIn()
                            }
                        }, label: {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text("Anmelden")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .cornerRadius(12)
                        })
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                        
                        // OAuth Divider
                        VStack(spacing: 12) {
                            Text("ODER ANMELDEN MIT")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                                .tracking(0.5)
                            
                            HStack(spacing: 12) {
                                // Google Sign In
                                Button(action: {
                                    Task {
                                        await authService.signInWithGoogle()
                                    }
                                }, label: {
                                    HStack {
                                        Image(systemName: "globe")
                                        Text("Google")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                })
                                
                                // GitHub Sign In
                                Button(action: {
                                    Task {
                                        await authService.signInWithGitHub()
                                    }
                                }, label: {
                                    HStack {
                                        Image(systemName: "swift")
                                        Text("GitHub")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                                })
                            }
                        }
                        
                        // Register Link
                        HStack {
                            Text("Noch kein Konto?")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Button("Registrieren") {
                                showRegistration = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
        }
        .alert("Login Error", isPresented: .constant(authService.errorMessage != nil)) {
            Button("OK") {
                authService.errorMessage = nil
            }
            
            // Show resend button if error mentions email confirmation
            if authService.errorMessage?.contains("bestätigen") == true {
                Button("E-Mail erneut senden") {
                    Task {
                        await authService.resendConfirmationEmail(email: email)
                        authService.errorMessage = nil
                    }
                }
            }
        } message: {
            Text(authService.errorMessage ?? "")
        }
    }
    
    private func signIn() async {
        let success = await authService.signIn(email: email, password: password)
        if success {
            // Handle successful login - navigation will be handled by the main app
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SupabaseAuthService())
} 
