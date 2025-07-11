//
//  ActiveRoundView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct ActiveRoundView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @EnvironmentObject private var dataService: SupabaseDataService
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var inProgressRound: InProgressRound
    @State private var showingFinishConfirmation = false
    @State private var showingExitConfirmation = false
    @State private var isFinishingRound = false
    @State private var finishError: String?
    
    private var currentHole: InProgressHoleScore? {
        inProgressRound.holes.first { $0.holeNumber == inProgressRound.currentHole }
    }
    
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
                    // Header with course info and score
                    RoundHeaderView(inProgressRound: inProgressRound) {
                        showingExitConfirmation = true
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Hole Navigation
                            HoleNavigationView(inProgressRound: inProgressRound)
                            
                            // Current Hole Input
                            if let hole = currentHole {
                                HoleInputCard(
                                    hole: hole,
                                    onUpdate: { strokes, putts, fairway, gir in
                                        inProgressRound.updateHoleScore(
                                            holeNumber: hole.holeNumber,
                                            strokes: strokes,
                                            putts: putts,
                                            fairwayHit: fairway,
                                            greenInRegulation: gir
                                        )
                                    },
                                    onParUpdate: { par in
                                        inProgressRound.updateHolePar(holeNumber: hole.holeNumber, par: par)
                                    }
                                )
                            }
                            
                            // Navigation Buttons
                            HoleNavigationButtons(inProgressRound: inProgressRound)
                            
                            // Progress Overview
                            ProgressOverviewCard(inProgressRound: inProgressRound)
                            
                            // Finish Round Button
                            if inProgressRound.completedHoles == inProgressRound.numberOfHoles {
                                FinishRoundButton {
                                    showingFinishConfirmation = true
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Runde verlassen?", isPresented: $showingExitConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Verlassen", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Deine Fortschritte gehen verloren, wenn du die Runde verlässt.")
        }
        .alert("Runde beenden?", isPresented: $showingFinishConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Beenden") {
                Task {
                    await finishRound()
                }
            }
        } message: {
            Text("Möchtest du diese Runde wirklich beenden und speichern?")
        }
        .alert("Fehler", isPresented: .constant(finishError != nil)) {
            Button("OK") {
                finishError = nil
            }
        } message: {
            if let error = finishError {
                Text(error)
            }
        }
    }
    
    private func finishRound() async {
        guard let request = inProgressRound.toCreateRoundRequest() else {
            finishError = "Runde ist nicht vollständig"
            return
        }
        
        isFinishingRound = true
        
        do {
            _ = try await dataService.createRound(request)
            inProgressRound.reset()
            dismiss()
        } catch {
            finishError = "Fehler beim Speichern: \(error.localizedDescription)"
        }
        
        isFinishingRound = false
    }
}

struct RoundHeaderView: View {
    @ObservedObject var inProgressRound: InProgressRound
    let onExit: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Top navigation
            HStack {
                Button(action: onExit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack {
                    Text(inProgressRound.courseName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(inProgressRound.numberOfHoles) Löcher")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Score display
                VStack {
                    Text("\(inProgressRound.totalScore)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Score")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Progress bar
            HStack {
                Text("Fortschritt: \(inProgressRound.completedHoles)/\(inProgressRound.numberOfHoles)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if inProgressRound.completedHoles > 0 {
                    let relative = inProgressRound.scoreRelativeToPar
                    Text(relative == 0 ? "Par" : (relative > 0 ? "+\(relative)" : "\(relative)"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * (Double(inProgressRound.completedHoles) / Double(inProgressRound.numberOfHoles)), height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
    }
}

struct HoleNavigationView: View {
    @ObservedObject var inProgressRound: InProgressRound
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(inProgressRound.holes) { hole in
                    HoleNumberButton(
                        hole: hole,
                        isSelected: hole.holeNumber == inProgressRound.currentHole,
                        onTap: {
                            inProgressRound.currentHole = hole.holeNumber
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct HoleNumberButton: View {
    let hole: InProgressHoleScore
    let isSelected: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isSelected {
            return .white
        } else if hole.isCompleted {
            return Color.green.opacity(0.8)
        } else {
            return Color.white.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return Color(red: 0.2, green: 0.8, blue: 0.4)
        } else if hole.isCompleted {
            return .white
        } else {
            return .white
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(hole.holeNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textColor)
                
                if let strokes = hole.strokes {
                    Text("\(strokes)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(textColor.opacity(0.8))
                }
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .cornerRadius(8)
        }
    }
}

struct HoleInputCard: View {
    let hole: InProgressHoleScore
    let onUpdate: (Int, Int?, Bool?, Bool?) -> Void
    let onParUpdate: (Int) -> Void
    
    @State private var strokes: String = ""
    @State private var putts: String = ""
    @State private var fairwayHit: Bool? = nil
    @State private var greenInRegulation: Bool? = nil
    @State private var par: Int = 4
    
    var body: some View {
        VStack(spacing: 20) {
            // Hole Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Loch \(hole.holeNumber)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                                         VStack(alignment: .leading, spacing: 8) {
                         HStack {
                             Text("Par")
                                 .font(.system(size: 14))
                                 .foregroundColor(.gray)
                             
                             Picker("Par", selection: $par) {
                                 ForEach(3...6, id: \.self) { parValue in
                                     Text("\(parValue)").tag(parValue)
                                 }
                             }
                             .pickerStyle(SegmentedPickerStyle())
                             .frame(width: 120)
                         }
                         
                         // Show distance and handicap if available from API
                         if let distance = hole.distanceMeters {
                             Text("\(Int(distance))m")
                                 .font(.system(size: 12))
                                 .foregroundColor(.gray)
                         }
                         
                         if let handicap = hole.handicap {
                             Text("HCP: \(handicap)")
                                 .font(.system(size: 12))
                                 .foregroundColor(.gray)
                         }
                     }
                }
                
                Spacer()
                
                if let strokes = hole.strokes {
                    ScoreDisplayView(strokes: strokes, par: hole.par)
                }
            }
            
            // Score Input
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Schläge *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        
                        TextField("0", text: $strokes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Putts")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        
                        TextField("0", text: $putts)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                    }
                }
                
                // Fairway and GIR toggles
                VStack(spacing: 12) {
                    HStack {
                        Text("Fairway getroffen")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button("Ja") {
                                fairwayHit = true
                            }
                            .buttonStyle(ToggleButtonStyle(isSelected: fairwayHit == true))
                            
                            Button("Nein") {
                                fairwayHit = false
                            }
                            .buttonStyle(ToggleButtonStyle(isSelected: fairwayHit == false))
                            
                            Button("n/a") {
                                fairwayHit = nil
                            }
                            .buttonStyle(ToggleButtonStyle(isSelected: fairwayHit == nil))
                        }
                    }
                    
                    HStack {
                        Text("Green in Regulation")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button("Ja") {
                                greenInRegulation = true
                            }
                            .buttonStyle(ToggleButtonStyle(isSelected: greenInRegulation == true))
                            
                            Button("Nein") {
                                greenInRegulation = false
                            }
                            .buttonStyle(ToggleButtonStyle(isSelected: greenInRegulation == false))
                            
                            Button("n/a") {
                                greenInRegulation = nil
                            }
                            .buttonStyle(ToggleButtonStyle(isSelected: greenInRegulation == nil))
                        }
                    }
                }
            }
            
            // Save Button
            Button(action: saveHoleScore) {
                Text("Loch speichern")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(strokes.isEmpty ? Color.gray : Color(red: 0.2, green: 0.8, blue: 0.4))
                    .cornerRadius(12)
            }
            .disabled(strokes.isEmpty)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            setupInitialValues()
        }
        .onChange(of: par) { newPar in
            onParUpdate(newPar)
        }
    }
    
    private func setupInitialValues() {
        par = hole.par
        strokes = hole.strokes != nil ? "\(hole.strokes!)" : ""
        putts = hole.putts != nil ? "\(hole.putts!)" : ""
        fairwayHit = hole.fairwayHit
        greenInRegulation = hole.greenInRegulation
    }
    
    private func saveHoleScore() {
        guard let strokeCount = Int(strokes), strokeCount > 0 else { return }
        
        let puttCount = Int(putts)
        
        onUpdate(strokeCount, puttCount, fairwayHit, greenInRegulation)
    }
}

struct ToggleButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isSelected ? .white : Color(red: 0.2, green: 0.8, blue: 0.4))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color.gray.opacity(0.2))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ScoreDisplayView: View {
    let strokes: Int
    let par: Int
    
    private var scoreColor: Color {
        let relative = strokes - par
        if relative < 0 { return .green }
        else if relative == 0 { return .blue }
        else if relative <= 2 { return .orange }
        else { return .red }
    }
    
    private var scoreText: String {
        let relative = strokes - par
        if relative == 0 { return "Par" }
        else if relative > 0 { return "+\(relative)" }
        else { return "\(relative)" }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(strokes)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(scoreColor)
            
            Text(scoreText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(scoreColor)
        }
    }
}

struct HoleNavigationButtons: View {
    @ObservedObject var inProgressRound: InProgressRound
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if inProgressRound.currentHole > 1 {
                    inProgressRound.currentHole -= 1
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Vorheriges")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(inProgressRound.currentHole > 1 ? Color.white.opacity(0.2) : Color.gray.opacity(0.3))
                .cornerRadius(8)
            }
            .disabled(inProgressRound.currentHole <= 1)
            
            Spacer()
            
            Button(action: {
                if inProgressRound.currentHole < inProgressRound.numberOfHoles {
                    inProgressRound.currentHole += 1
                }
            }) {
                HStack {
                    Text("Nächstes")
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(inProgressRound.currentHole < inProgressRound.numberOfHoles ? Color.white.opacity(0.2) : Color.gray.opacity(0.3))
                .cornerRadius(8)
            }
            .disabled(inProgressRound.currentHole >= inProgressRound.numberOfHoles)
        }
    }
}

struct ProgressOverviewCard: View {
    @ObservedObject var inProgressRound: InProgressRound
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Überblick")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            HStack {
                StatColumn(title: "Löcher", value: "\(inProgressRound.completedHoles)/\(inProgressRound.numberOfHoles)")
                Spacer()
                StatColumn(title: "Score", value: "\(inProgressRound.totalScore)")
                Spacer()
                StatColumn(title: "Par", value: inProgressRound.totalPar > 0 ? "\(inProgressRound.totalPar)" : "--")
                Spacer()
                StatColumn(title: "Zu Par", value: inProgressRound.completedHoles > 0 ? (inProgressRound.scoreRelativeToPar >= 0 ? "+\(inProgressRound.scoreRelativeToPar)" : "\(inProgressRound.scoreRelativeToPar)") : "--")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct StatColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

struct FinishRoundButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Runde beenden")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.green)
            .cornerRadius(16)
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