//
//  ActiveRoundView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/11/25.
//

import SwiftUI

struct ActiveRoundView: View {
    @ObservedObject var inProgressRound: InProgressRound
    @EnvironmentObject var authService: SupabaseAuthService
    @EnvironmentObject var dataService: SupabaseDataService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingFinishAlert = false
    @State private var isFinishing = false
    @State private var showingScore = false
    @State private var finishedScore: Int?
    
    var currentHole: InProgressHoleScore {
        inProgressRound.holes[inProgressRound.currentHole - 1]
    }
    
    var canFinishRound: Bool {
        inProgressRound.completedHoles == inProgressRound.numberOfHoles
    }
    
    var body: some View {
            ZStack {
            // Background gradient
                LinearGradient(
                colors: [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.15, green: 0.6, blue: 0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            ScrollView {
                VStack(spacing: 24) {
                    // Header with course info and navigation
                    headerSection
                    
                    // Current hole display
                    currentHoleCard
                    
                    // Show score if hole is completed
                    if let strokes = currentHole.strokes {
                        completedHoleScoreCard(strokes: strokes)
                    }
                    
                    // Hole score input (only if not completed)
                    if currentHole.strokes == nil {
                        HoleScoreInput(
                            hole: currentHole,
                            onUpdate: updateHoleScore,
                            onParUpdate: updateHolePar
                                )
                            }
                            
                    // Progress overview
                            ProgressOverviewCard(inProgressRound: inProgressRound)
                            
                    // Navigation buttons
                    HoleNavigationButtons(inProgressRound: inProgressRound)
                    
                    // Finish round button
                    if canFinishRound {
                        FinishRoundButton(action: {
                            showingFinishAlert = true
                        })
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Abbrechen") {
                    presentationMode.wrappedValue.dismiss()
            }
                .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Überblick") {
                    // Show round overview (navigation to summary view would be implemented here)
                    showRoundOverview()
                }
                .foregroundColor(.white)
            }
        }
        .alert("Runde beenden", isPresented: $showingFinishAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Beenden") {
                finishRound()
            }
        } message: {
            Text("Möchten Sie die Runde wirklich beenden? Dies kann nicht rückgängig gemacht werden.")
        }
        .alert("Runde beendet!", isPresented: $showingScore) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            if let score = finishedScore {
                Text("Ihre finale Punktzahl: \(score)")
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
                    Text(inProgressRound.courseName)
                .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Loch \(inProgressRound.currentHole) von \(inProgressRound.numberOfHoles)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.top, 20)
        }
    
    private var currentHoleCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loch \(currentHole.holeNumber)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Par \(currentHole.par)")
                        .font(.system(size: 16, weight: .medium))
                                 .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Hole completion indicator
                Circle()
                    .fill(currentHole.strokes != nil ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
            
            if let strokes = currentHole.strokes {
                Divider()
                
                    HStack {
                    Text("Schläge: \(strokes)")
                        .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                    if let putts = currentHole.putts {
                        Text("Putts: \(putts)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func completedHoleScoreCard(strokes: Int) -> some View {
        VStack(spacing: 16) {
            Text("Loch abgeschlossen!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            ScoreDisplayView(strokes: strokes, par: currentHole.par)
            
            Button("Score bearbeiten") {
                // Allow editing the score
                inProgressRound.updateHoleScore(
                    holeNumber: currentHole.holeNumber,
                    strokes: nil,
                    putts: nil,
                    fairwayHit: nil,
                    greenInRegulation: nil
                )
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Actions
    
    private func updateHoleScore(strokes: Int, putts: Int?, fairwayHit: Bool?, greenInRegulation: Bool?) {
        inProgressRound.updateHoleScore(
            holeNumber: inProgressRound.currentHole,
            strokes: strokes,
            putts: putts,
            fairwayHit: fairwayHit,
            greenInRegulation: greenInRegulation
        )
        
        // Auto-advance to next hole if available
        if inProgressRound.currentHole < inProgressRound.numberOfHoles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                inProgressRound.currentHole += 1
            }
        }
    }
    
    private func updateHolePar(_ newPar: Int) {
        inProgressRound.updateHolePar(holeNumber: inProgressRound.currentHole, par: newPar)
    }
    
    private func showRoundOverview() {
        // Round overview functionality - could show a summary sheet or navigate to overview
        print("Round Overview: \(inProgressRound.completedHoles)/\(inProgressRound.numberOfHoles) holes completed, Current score: \(inProgressRound.totalScore)")
        }
    
    private func finishRound() {
        guard canFinishRound else { return }
        
        isFinishing = true
        finishedScore = inProgressRound.totalScore
        
        Task {
            do {
                let createRequest = CreateRoundRequest(
                    courseName: inProgressRound.courseName,
                    date: Date(),
                    totalScore: inProgressRound.totalScore,
                    par: inProgressRound.totalPar,
                    holes: inProgressRound.holes.map { hole in
                        CreateHoleScoreRequest(
                            holeNumber: hole.holeNumber,
                            par: hole.par,
                            strokes: hole.strokes ?? 0,
                            putts: hole.putts,
                            fairwayHit: hole.fairwayHit,
                            greenInRegulation: hole.greenInRegulation
                        )
                    },
                    notes: nil
                )
                
                _ = try await dataService.createRound(createRequest)
                
                await MainActor.run {
                    isFinishing = false
                    showingScore = true
                }
            } catch {
                await MainActor.run {
                    isFinishing = false
                    // Show error message to user
                    print("Error finishing round: \(error)")
                    // Note: Error handling should show user-friendly alert
                }
            }
        }
    }
}

#Preview {
    let authService = SupabaseAuthService()
    let inProgressRound = InProgressRound(courseName: "Test Golf Club", numberOfHoles: 9)
    
    return ActiveRoundView(inProgressRound: inProgressRound)
        .environmentObject(authService)
        .environmentObject(SupabaseDataService(authService: authService))
} 
