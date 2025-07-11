//
//  CreateCourseView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct CreateCourseView: View {
    @ObservedObject var apiService: GolfCourseAPIService
    @Environment(\.dismiss) private var dismiss
    @State private var courseName = ""
    @State private var location = ""
    @State private var country = "Deutschland"
    @State private var numberOfHoles = 18
    @State private var isCreating = false
    @State private var createError: String?
    
    let onCourseCreated: (CourseSearchResult) -> Void
    
    private let countries = [
        "Deutschland", "Österreich", "Schweiz", "Niederlande", 
        "Belgien", "Frankreich", "Italien", "Spanien", "England", "Schottland"
    ]
    
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
                    // Header
                    HStack {
                        Button("Abbrechen") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Neuer Golfplatz")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Erstellen") {
                            Task {
                                await createCourse()
                            }
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .disabled(courseName.isEmpty || location.isEmpty || isCreating)
                        .opacity(courseName.isEmpty || location.isEmpty || isCreating ? 0.5 : 1.0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Icon
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Neuen Golfplatz hinzufügen")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 20)
                            
                            // Form
                            VStack(spacing: 16) {
                                // Course Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name des Golfplatzes *")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    TextField("z.B. Golf Club Musterplatz", text: $courseName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.system(size: 16))
                                }
                                
                                // Location
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Ort/Stadt *")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    TextField("z.B. München", text: $location)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.system(size: 16))
                                }
                                
                                // Country
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Land")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Picker("Land", selection: $country) {
                                        ForEach(countries, id: \.self) { country in
                                            Text(country).tag(country)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                // Number of Holes
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Anzahl Löcher")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 12) {
                                        ForEach([9, 18], id: \.self) { holes in
                                            Button(action: {
                                                numberOfHoles = holes
                                            }) {
                                                VStack(spacing: 4) {
                                                    Text("\(holes)")
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(numberOfHoles == holes ? .white : Color(red: 0.2, green: 0.8, blue: 0.4))
                                                    
                                                    Text("Löcher")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(numberOfHoles == holes ? .white : .gray)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 60)
                                                .background(numberOfHoles == holes ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 20)
                            
                            // Error Message
                            if let error = createError {
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Info
                            VStack(spacing: 8) {
                                Text("💡 Hinweis")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Der neue Golfplatz wird zu Ihrer lokalen Liste hinzugefügt und kann sofort für Runden verwendet werden.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createCourse() async {
        guard !courseName.isEmpty && !location.isEmpty else { return }
        
        isCreating = true
        createError = nil
        
        do {
            let newCourse = try await apiService.createNewCourse(
                name: courseName,
                location: location,
                country: country,
                holes: numberOfHoles
            )
            
            onCourseCreated(newCourse)
            dismiss()
            
        } catch {
            createError = "Fehler beim Erstellen: \(error.localizedDescription)"
        }
        
        isCreating = false
    }
}

#Preview {
    let apiService = GolfCourseAPIService()
    return CreateCourseView(apiService: apiService) { _ in }
} 