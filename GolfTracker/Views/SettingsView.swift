//
//  SettingsView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

// MARK: - Settings Components

struct SettingsHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "flag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
            }
            
            VStack(spacing: 2) {
                Text("Einstellungen")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Verwalten Sie Ihr Profil und Ihre Daten")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 5)
    }
}

struct ProfileSectionView: View {
    @Binding var userName: String
    let userEmail: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                Text("Profil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                        .frame(width: 16)
                        .font(.system(size: 14))
                    
                    TextField("Ihr Name", text: $userName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .autocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit {
                            hideKeyboard()
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("E-Mail")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                        .frame(width: 16)
                        .font(.system(size: 14))
                    
                    Text(userEmail)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct GolfDataSectionView: View {
    @Binding var handicap: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                Text("Golf Daten")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Handicap")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.gray)
                        .frame(width: 16)
                        .font(.system(size: 14))
                    
                    TextField("z.B. 18.5", text: $handicap)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .keyboardType(.decimalPad)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Fertig") {
                                    hideKeyboard()
                                }
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            }
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("Ihr aktuelles Golf-Handicap (optional)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AccountSectionView: View {
    let logoutAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                Text("Konto")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            Button(action: logoutAction, label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14))
                    Text("Abmelden")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            })
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @EnvironmentObject private var dataService: SupabaseDataService
    @Environment(\.dismiss) private var dismiss
    
    @State private var userName: String = ""
    @State private var handicap: String = ""
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
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
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Back Button - positioned at top left
                        HStack {
                            Button(action: {
                                hideKeyboard()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    dismiss()
                                }
                            }, label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                            })
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 5)
                        
                        // Header Section
                        SettingsHeaderView()
                        
                        // Fixed height container for Success/Error Messages (kompakter)
                        VStack {
                            if let successMessage = successMessage {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 12))
                                    Text(successMessage)
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                                .transition(.opacity)
                            } else if let errorMessage = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 12))
                                    Text(errorMessage)
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .transition(.opacity)
                            } else {
                                // Empty placeholder to maintain layout
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 1)
                            }
                        }
                        .frame(minHeight: 35)
                        .padding(.horizontal)
                        
                        // Settings Form Card (kompakter)
                        VStack(spacing: 16) {
                            // Profile Section
                            ProfileSectionView(
                                userName: $userName,
                                userEmail: authService.session?.user.email ?? ""
                            )
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Golf Section
                            GolfDataSectionView(handicap: $handicap)
                            
                            // Save Button
                            Button(action: {
                                hideKeyboard()
                                Task {
                                    await saveSettings()
                                }
                            }, label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text("Einstellungen speichern")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(red: 0.2, green: 0.8, blue: 0.4))
                                .cornerRadius(8)
                            })
                            .disabled(isLoading)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Account Section
                            AccountSectionView {
                                    hideKeyboard()
                                    Task {
                                        await logout()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        
                        // Ensure bottom spacing for content visibility
                        Spacer(minLength: 30)
                    }
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    // Dismiss keyboard when tapping on background
                    hideKeyboard()
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                // Additional tap gesture for entire view
                hideKeyboard()
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        // Load current user name
        userName = authService.session?.user.name ?? ""
        
        // Load current handicap from stats
        if let stats = dataService.dashboardData.userStats {
            handicap = stats.handicapIndex.map { String(format: "%.1f", $0) } ?? ""
        }
    }
    
    private func saveSettings() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Update user name if changed
            let currentName = authService.session?.user.name ?? ""
            if userName != currentName && !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                try await dataService.updateUserName(newName: userName.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            // Update handicap if provided
            let handicapValue = Double(handicap.replacingOccurrences(of: ",", with: "."))
            try await dataService.updateUserHandicap(handicap: handicapValue)
            
            successMessage = "Einstellungen erfolgreich gespeichert!"
            
            // Refresh dashboard data
            await dataService.refreshData()
            
            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                successMessage = nil
            }
            
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func logout() async {
        await authService.signOut()
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    let authService = SupabaseAuthService()
    return SettingsView()
        .environmentObject(authService)
        .environmentObject(SupabaseDataService(authService: authService))
} 
