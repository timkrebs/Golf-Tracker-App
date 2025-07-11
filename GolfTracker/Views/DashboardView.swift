//
//  DashboardView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @EnvironmentObject private var dataService: SupabaseDataService
    @State private var showingSettings = false
    @State private var showingRoundHistory = false
    @State private var showingNewRound = false
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Settings Button - positioned at top right
                        HStack {
                            Spacer()
                            Button(action: {
                                showingSettings = true
                            }, label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                            })
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Error message if any
                        if let errorMessage = dataService.dashboardData.errorMessage {
                            VStack(spacing: 8) {
                                Text("⚠️ Fehler")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                Button("Erneut versuchen") {
                                    Task {
                                        await dataService.refreshData()
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Header
                        VStack(spacing: 16) {
                        // Golf Flag Icon
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "flag.fill")
                                .font(.system(size: 25))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Willkommen zurück!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let user = authService.session?.user {
                                Text("Hallo, \(user.name ?? user.email)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Quick Stats Cards
                    if dataService.dashboardData.isLoading {
                        ProgressView("Daten werden geladen...")
                            .foregroundColor(.white)
                            .padding()
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Runden gespielt",
                                value: "\(dataService.dashboardData.userStats?.totalRounds ?? 0)",
                                icon: "figure.golf",
                                color: .white
                            )
                            
                            StatCard(
                                title: "Handicap",
                                value: {
                                    if let handicap = dataService.dashboardData.userStats?.handicapIndex {
                                        return String(format: "%.1f", handicap)
                                    } else {
                                        return "--"
                                    }
                                }(),
                                icon: "target",
                                color: .white
                            )
                            
                            StatCard(
                                title: "Beste Runde",
                                value: {
                                    if let bestScore = dataService.dashboardData.userStats?.bestScore {
                                        return "\(bestScore)"
                                    } else {
                                        return "--"
                                    }
                                }(),
                                icon: "trophy.fill",
                                color: .white
                            )
                            
                            StatCard(
                                title: "Lieblingsbahn",
                                value: dataService.dashboardData.userStats?.favoriteCourse ?? "--",
                                icon: "location.fill",
                                color: .white
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showingNewRound = true
                        }, label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Neue Runde starten")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                        })
                        
                        Button(action: {
                            showingRoundHistory = true
                        }, label: {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 20))
                                Text("Rundenverlauf")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                        })
                    }
                    .padding(.horizontal)
                    
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await dataService.refreshData()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authService)
                    .environmentObject(dataService)
            }
            .fullScreenCover(isPresented: $showingRoundHistory) {
                RoundHistoryView()
                    .environmentObject(authService)
                    .environmentObject(dataService)
            }
            .fullScreenCover(isPresented: $showingNewRound) {
                NewRoundView()
                    .environmentObject(authService)
                    .environmentObject(dataService)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(color)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    let authService = SupabaseAuthService()
    return DashboardView()
        .environmentObject(authService)
        .environmentObject(SupabaseDataService(authService: authService))
} 
