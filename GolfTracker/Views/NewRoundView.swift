//
//  NewRoundView.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import SwiftUI

struct NewRoundView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @EnvironmentObject private var dataService: SupabaseDataService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var inProgressRound = InProgressRound()
    @StateObject private var apiService = GolfCourseAPIService()
    @State private var showingActiveRound = false
    @State private var isLoadingCourse = false
    @State private var selectedCourse: CourseSearchResult?
    @State private var showingCreateCourse = false
    
    // Common golf courses for suggestions
    private let commonCourses = [
        "Golf Club Gut Häusern",
        "Golfclub München Eichenried",
        "Golf & Country Club München-Riem",
        "Golfclub Bad Abbach",
        "Golf Resort Bad Griesbach",
        "Golfclub Schloss Egmating",
        "Golf Club Starnberg",
        "Golfclub Dachau",
        "Golf Club Erding",
        "Golfplatz Holledau"
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
                    // Custom Navigation Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        })
                        
                        Spacer()
                        
                        Text("Neue Runde")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 42, height: 42)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header Icon
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Bereit für eine neue Runde?")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 20)
                            
                            // Course Selection Card
                            VStack(spacing: 20) {
                                CourseListCard(
                                    courseName: $inProgressRound.courseName,
                                    selectedCourse: $selectedCourse,
                                    apiService: apiService,
                                    onCreateNewCourse: {
                                        showingCreateCourse = true
                                    }
                                )
                                
                                // Holes Selection Card
                                HolesSelectionCard(
                                    numberOfHoles: $inProgressRound.numberOfHoles
                                )
                                
                                // Date Card
                                DateSelectionCard(
                                    date: $inProgressRound.startDate
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Start Round Button
                            VStack(spacing: 12) {
                                Button(action: {
                                    startRound()
                                }, label: {
                                    HStack {
                                        if isLoadingCourse {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 20))
                                        }
                                        
                                        Text(isLoadingCourse ? "Lade Platzdaten..." : "Runde starten")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .foregroundColor(inProgressRound.courseName.isEmpty ? .gray : Color(red: 0.2, green: 0.8, blue: 0.4))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                })
                                .disabled(inProgressRound.courseName.isEmpty || isLoadingCourse)
                                .opacity(inProgressRound.courseName.isEmpty || isLoadingCourse ? 0.6 : 1.0)
                                
                                Text("Wähle zuerst einen Golfplatz aus")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .opacity(inProgressRound.courseName.isEmpty ? 1.0 : 0.0)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingActiveRound) {
            ActiveRoundView(inProgressRound: inProgressRound)
                .environmentObject(authService)
                .environmentObject(dataService)
        }
        .sheet(isPresented: $showingCreateCourse) {
            CreateCourseView(apiService: apiService) { newCourse in
                selectedCourse = newCourse
                inProgressRound.courseName = newCourse.name
            }
        }
        .onAppear {
            // Load all courses on first load
            Task {
                await apiService.loadAllCourses()
            }
        }
    }
    
    private func startRound() {
        guard !inProgressRound.courseName.isEmpty else { return }
        
        if let selectedCourse = selectedCourse {
            // Load course data from API
            Task {
                await loadCourseData(selectedCourse)
            }
        } else {
            // Use manual course entry
            showingActiveRound = true
        }
    }
    
    private func loadCourseData(_ course: CourseSearchResult) async {
        isLoadingCourse = true
        
        do {
            let scorecard = try await apiService.getScorecard(
                courseId: course.id,
                holes: inProgressRound.numberOfHoles
            )
            
            inProgressRound.setupFromScorecard(scorecard)
            showingActiveRound = true
            
        } catch {
            // Fallback to manual entry if API fails
            inProgressRound.courseName = course.name
            inProgressRound.courseLocation = "\(course.location), \(course.country)"
            showingActiveRound = true
        }
        
        isLoadingCourse = false
    }
}

struct CourseListCard: View {
    @Binding var courseName: String
    @Binding var selectedCourse: CourseSearchResult?
    @ObservedObject var apiService: GolfCourseAPIService
    let onCreateNewCourse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                
                Text("Golfplatz auswählen")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                if apiService.isLoadingAll {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            VStack(spacing: 12) {
                // Create New Course Button
                Button(action: onCreateNewCourse) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        
                        Text("Neuen Golfplatz anlegen")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.2, green: 0.8, blue: 0.4), lineWidth: 1)
                    )
                }
                
                // Divider
                if !apiService.allCourses.isEmpty {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 4)
                }
                
                // Course List
                if apiService.isLoadingAll {
                    VStack(spacing: 12) {
                        Text("Lade Golfplätze...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    
                } else if apiService.allCourses.isEmpty {
                    VStack(spacing: 8) {
                        Text("Keine Golfplätze verfügbar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("Erstellen Sie einen neuen Golfplatz oder versuchen Sie es später erneut.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(apiService.allCourses) { course in
                                Button(action: {
                                    selectedCourse = course
                                    courseName = course.name
                                }, label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(course.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.leading)
                                            Text("\(course.location), \(course.country)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(course.totalHoles)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                                            Text("Löcher")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedCourse?.id == course.id ? Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1) : Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedCourse?.id == course.id ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color.clear, lineWidth: 2)
                                    )
                                })
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                
                // Selected Course Display
                if let selected = selectedCourse {
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.vertical, 4)
                        
                        HStack {
                            Text("✅ Ausgewählt")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selected.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Text("\(selected.location), \(selected.country)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(selected.totalHoles)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                                
                                Text("Löcher")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                        .background(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.2, green: 0.8, blue: 0.4), lineWidth: 2)
                        )
                    }
                }
                
                // Error Message
                if let error = apiService.searchError {
                    VStack(spacing: 8) {
                        Text("⚠️ \(error)")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Erneut versuchen") {
                            Task {
                                await apiService.loadAllCourses()
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct HolesSelectionCard: View {
    @Binding var numberOfHoles: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "number.circle")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                
                Text("Anzahl Löcher")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach([9, 18], id: \.self) { holes in
                    Button(action: {
                        numberOfHoles = holes
                    }, label: {
                        VStack(spacing: 8) {
                            Text("\(holes)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(numberOfHoles == holes ? .white : Color(red: 0.2, green: 0.8, blue: 0.4))
                            Text("Löcher")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(numberOfHoles == holes ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(numberOfHoles == holes ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    })
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct DateSelectionCard: View {
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                
                Text("Datum")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .accentColor(Color(red: 0.2, green: 0.8, blue: 0.4))
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    let authService = SupabaseAuthService()
    return NewRoundView()
        .environmentObject(authService)
        .environmentObject(SupabaseDataService(authService: authService))
} 
