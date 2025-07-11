//
//  RoundComponents.swift
//  GolfTracker
//
//  Created by AI on 11/7/25.
//

import SwiftUI

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