//
//  RoundHistoryView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct RoundHistoryView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @EnvironmentObject private var dataService: SupabaseDataService
    @Environment(\.dismiss) private var dismiss
    @State private var allRounds: [GolfRound] = []
    @State private var isLoading = true
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
                
                VStack(spacing: 0) {
                    // Custom Navigation Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Text("Rundenverlauf")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    if isLoading {
                        Spacer()
                        ProgressView("Runden werden geladen...")
                            .foregroundColor(.white)
                        Spacer()
                    } else if let errorMessage = errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("⚠️ Fehler")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            Button("Erneut versuchen") {
                                Task {
                                    await loadRounds()
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                // Statistics Section
                                if !allRounds.isEmpty {
                                    VStack(spacing: 16) {
                                        Text("Statistiken der letzten Runden")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.top, 20)
                                        
                                        StatisticsSection(rounds: allRounds)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Rounds List Header
                                    HStack {
                                        Text("Alle Runden (\(allRounds.count))")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                }
                                
                                // Rounds List
                                if allRounds.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "figure.golf")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Text("Noch keine Runden gespielt")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Text("Starte deine erste Golfrunde!")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.top, 60)
                                } else {
                                    ForEach(allRounds) { round in
                                        RoundCard(round: round)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                
                                // Bottom spacing
                                Color.clear.frame(height: 20)
                            }
                        }
                        .refreshable {
                            await loadRounds()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadRounds()
        }
    }
    
    private func loadRounds() async {
        guard let userId = authService.session?.user.id else {
            errorMessage = "User not authenticated"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            allRounds = try await dataService.fetchAllRounds(userId: userId)
            isLoading = false
        } catch {
            errorMessage = "Fehler beim Laden der Runden: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

struct StatisticsSection: View {
    let rounds: [GolfRound]
    
    private var recentRounds: [GolfRound] {
        Array(rounds.prefix(10))
    }
    
    private var averageScore: Double {
        guard !recentRounds.isEmpty else { return 0 }
        return Double(recentRounds.map { $0.totalScore }.reduce(0, +)) / Double(recentRounds.count)
    }
    
    private var averageRelativeToPar: Double {
        guard !recentRounds.isEmpty else { return 0 }
        return Double(recentRounds.map { $0.scoreRelativeToPar }.reduce(0, +)) / Double(recentRounds.count)
    }
    
    private var bestRecentScore: Int? {
        recentRounds.map { $0.totalScore }.min()
    }
    
    private var trendIndicator: (icon: String, color: Color, text: String) {
        if rounds.count < 2 {
            return ("minus", .gray, "Keine Tendenz")
        }
        
        let recent5 = Array(rounds.prefix(5))
        let previous5 = Array(rounds.dropFirst(5).prefix(5))
        
        guard !previous5.isEmpty else {
            return ("minus", .gray, "Keine Tendenz")
        }
        
        let recentAvg = Double(recent5.map { $0.totalScore }.reduce(0, +)) / Double(recent5.count)
        let previousAvg = Double(previous5.map { $0.totalScore }.reduce(0, +)) / Double(previous5.count)
        
        if recentAvg < previousAvg - 1 {
            return ("arrow.up", .green, "Verbesserung")
        } else if recentAvg > previousAvg + 1 {
            return ("arrow.down", .red, "Verschlechterung")
        } else {
            return ("minus", .orange, "Konstant")
        }
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "Ø letzte 10",
                value: String(format: "%.1f", averageScore),
                icon: "chart.line.uptrend.xyaxis",
                color: .white
            )
            
            StatCard(
                title: "Ø zu Par",
                value: averageRelativeToPar >= 0 ? "+\(String(format: "%.1f", averageRelativeToPar))" : String(format: "%.1f", averageRelativeToPar),
                icon: "target",
                color: .white
            )
            
            StatCard(
                title: "Bester Score",
                value: bestRecentScore != nil ? "\(bestRecentScore!)" : "--",
                icon: "star.fill",
                color: .white
            )
            
            VStack(spacing: 8) {
                Image(systemName: trendIndicator.icon)
                    .font(.system(size: 20))
                    .foregroundColor(trendIndicator.color)
                
                VStack(spacing: 4) {
                    Text("Tendenz")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(trendIndicator.text)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct RoundCard: View {
    let round: GolfRound
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: round.date)
    }
    
    private var scoreColor: Color {
        let relative = round.scoreRelativeToPar
        if relative < 0 { return .green }
        else if relative == 0 { return .blue }
        else if relative <= 5 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(round.courseName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(round.totalScore)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text("(Par \(round.par))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color.white)
            
            // Score relative to par bar
            HStack {
                Text(round.scoreDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(scoreColor)
                
                Spacer()
                
                if let notes = round.notes, !notes.isEmpty {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(Color.white)
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    let authService = SupabaseAuthService()
    return RoundHistoryView()
        .environmentObject(authService)
        .environmentObject(SupabaseDataService(authService: authService))
} 