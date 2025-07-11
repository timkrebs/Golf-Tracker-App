//
//  HoleScoreInput.swift
//  GolfTracker
//
//  Created by AI on 11/7/25.
//

import SwiftUI

struct HoleScoreInput: View {
    let hole: InProgressHole
    let onUpdate: (Int, Int?, Bool?, Bool?) -> Void
    let onParUpdate: (Int) -> Void
    
    @State private var par: Int = 4
    @State private var strokes: String = ""
    @State private var putts: String = ""
    @State private var fairwayHit: Bool?
    @State private var greenInRegulation: Bool?
    
    var body: some View {
        VStack(spacing: 20) {
            // Par selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Par")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                HStack(spacing: 12) {
                    ForEach(3...6, id: \.self) { parValue in
                        Button(action: {
                            par = parValue
                            onParUpdate(parValue)
                        }) {
                            Text("\(parValue)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(par == parValue ? .white : Color(red: 0.2, green: 0.8, blue: 0.4))
                                .frame(width: 40, height: 40)
                                .background(par == parValue ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Strokes input
            VStack(alignment: .leading, spacing: 8) {
                Text("Schläge")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                TextField("Anzahl Schläge", text: $strokes)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
            }
            
            // Putts input
            VStack(alignment: .leading, spacing: 8) {
                Text("Putts (optional)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                TextField("Anzahl Putts", text: $putts)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
            }
            
            // Fairway and Green toggles
            VStack(spacing: 12) {
                HStack {
                    Text("Fairway getroffen")
                        .font(.system(size: 14, weight: .medium))
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
                        
                        Button("N/A") {
                            fairwayHit = nil
                        }
                        .buttonStyle(ToggleButtonStyle(isSelected: fairwayHit == nil))
                    }
                }
                
                HStack {
                    Text("Green in Regulation")
                        .font(.system(size: 14, weight: .medium))
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
                        
                        Button("N/A") {
                            greenInRegulation = nil
                        }
                        .buttonStyle(ToggleButtonStyle(isSelected: greenInRegulation == nil))
                    }
                }
            }
            
            // Save button
            Button(action: saveHoleScore) {
                Text("Score speichern")
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
        strokes = hole.strokes.map { "\($0)" } ?? ""
        putts = hole.putts.map { "\($0)" } ?? ""
        fairwayHit = hole.fairwayHit
        greenInRegulation = hole.greenInRegulation
    }
    
    private func saveHoleScore() {
        guard let strokeCount = Int(strokes), strokeCount > 0 else { return }
        
        let puttCount = Int(putts)
        
        onUpdate(strokeCount, puttCount, fairwayHit, greenInRegulation)
    }
} 