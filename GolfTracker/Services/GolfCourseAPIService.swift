//
//  GolfCourseAPIService.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation

// MARK: - API Models

struct APICGolfCourse: Codable {
    let id: Int?
    let name: String
    let location: String
    let country: String
    let totalHoles: Int
    let holes: [APIHole]
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, country, holes
        case totalHoles = "total_holes"
        case createdAt = "created_at"
    }
}

struct APIHole: Codable {
    let id: Int?
    let holeNumber: Int
    let par: Int
    let distanceMeters: Double
    let handicap: Int
    let golfCourseId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, par, handicap
        case holeNumber = "hole_number"
        case distanceMeters = "distance_meters"
        case golfCourseId = "golf_course_id"
    }
}

struct APIScorecard: Codable {
    let golfCourseId: Int
    let golfCourseName: String
    let location: String
    let country: String
    let holes: [APIScorecardHole]
    let totalPar: Int
    let totalDistance: Double
    
    enum CodingKeys: String, CodingKey {
        case location, country, holes
        case golfCourseId = "golf_course_id"
        case golfCourseName = "golf_course_name"
        case totalPar = "total_par"
        case totalDistance = "total_distance"
    }
}

struct APIScorecardHole: Codable {
    let holeNumber: Int
    let par: Int
    let distanceMeters: Double
    let handicap: Int
    let score: Int?
    
    enum CodingKeys: String, CodingKey {
        case par, handicap, score
        case holeNumber = "hole_number"
        case distanceMeters = "distance_meters"
    }
}

// MARK: - Search Response Models

struct GolfCourseSearchResponse: Codable {
    let courses: [CourseSearchResult]
    let total: Int?
    let page: Int?
    let perPage: Int?
    
    enum CodingKeys: String, CodingKey {
        case courses, total, page
        case perPage = "per_page"
    }
}

// Alternative response format - sometimes APIs return data differently
struct AlternativeSearchResponse: Codable {
    let data: [CourseSearchResult]
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case data, count
    }
}

struct CourseSearchResult: Codable, Identifiable {
    let id: Int
    let name: String
    let location: String
    let country: String
    let totalHoles: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, country
        case totalHoles = "total_holes"
    }
    
    var displayName: String {
        "\(name) - \(location), \(country)"
    }
}

// MARK: - API Service

@MainActor
class GolfCourseAPIService: ObservableObject {
    @Published var searchResults: [CourseSearchResult] = []
    @Published var allCourses: [CourseSearchResult] = []
    @Published var isSearching = false
    @Published var isLoadingAll = false
    @Published var searchError: String?
    @Published var showingCreateCourse = false
    
    private var baseURL: String {
        do {
            let config = try ConfigLoader.loadConfig()
            return config.golfAPIBaseURL
        } catch {
            print("⚠️ Failed to load API configuration, using fallback: \(error)")
            return "https://golftracker-app-service.azurewebsites.net"
        }
    }
    private let session = URLSession.shared
    
    // MARK: - Search Golf Courses
    
    func searchGolfCourses(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        do {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            // Try different possible API endpoints
            let possibleURLs = [
                "\(baseURL)/api/v1/golf-courses/search?q=\(encodedQuery)&limit=20",
                "\(baseURL)/golf-courses/search?q=\(encodedQuery)&limit=20",
                "\(baseURL)/api/golf-courses/search?q=\(encodedQuery)&limit=20",
                "\(baseURL)/courses/search?q=\(encodedQuery)&limit=20",
                "\(baseURL)/api/courses/search?q=\(encodedQuery)&limit=20",
                "\(baseURL)/search?q=\(encodedQuery)&limit=20"
            ]
            
            var lastError: Error?
            
            for urlString in possibleURLs {
                do {
                    guard let url = URL(string: urlString) else { continue }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    print("🔍 Trying URL: \(urlString)")
                    
                    let (data, response) = try await session.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continue
                    }
                    
                    print("📡 Response Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 404 {
                        continue // Try next URL
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        lastError = APIError.serverError(httpResponse.statusCode)
                        continue
                    }
                    
                    // Log response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Response: \(responseString.prefix(200))...")
                    }
                    
                    // Try to decode the response - multiple formats
                    do {
                        let searchResponse = try JSONDecoder().decode(GolfCourseSearchResponse.self, from: data)
                        searchResults = searchResponse.courses
                        isSearching = false
                        return // Success!
                    } catch {
                        print("❌ Primary decoding failed: \(error)")
                        
                        // Try alternative response format with "data" field
                        do {
                            let altResponse = try JSONDecoder().decode(AlternativeSearchResponse.self, from: data)
                            searchResults = altResponse.data
                            isSearching = false
                            return // Success!
                        } catch {
                            print("❌ Alternative 'data' decoding failed: \(error)")
                            
                            // Try direct array of courses
                            do {
                                let courses = try JSONDecoder().decode([CourseSearchResult].self, from: data)
                                searchResults = courses
                                isSearching = false
                                return // Success!
                            } catch {
                                print("❌ Direct array decoding failed: \(error)")
                                lastError = error
                            }
                        }
                    }
                    
                } catch {
                    print("❌ Network error for \(urlString): \(error)")
                    lastError = error
                }
            }
            
            // If we get here, all URLs failed
            throw lastError ?? APIError.invalidURL
            
        } catch {
            searchError = "Fehler bei der Suche: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    // MARK: - Get Golf Course Details
    
    func getGolfCourse(id: Int) async throws -> APICGolfCourse {
        guard let url = URL(string: "\(baseURL)/golf-courses/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(APICGolfCourse.self, from: data)
    }
    
    // MARK: - Get Scorecard
    
    func getScorecard(courseId: Int, holes: Int? = nil) async throws -> APIScorecard {
        var urlString = "\(baseURL)/golf-courses/\(courseId)/scorecard"
        if let holes = holes {
            urlString += "?holes=\(holes)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(APIScorecard.self, from: data)
    }
    
    // MARK: - Load All Courses
    
    func loadAllCourses() async {
        isLoadingAll = true
        searchError = nil
        
        do {
            // Try different possible endpoints for getting all courses
            let possibleURLs = [
                "\(baseURL)/api/v1/golf-courses?limit=20",
                "\(baseURL)/golf-courses?limit=20",
                "\(baseURL)/api/golf-courses?limit=20",
                "\(baseURL)/courses?limit=20",
                "\(baseURL)/api/courses?limit=20"
            ]
            
            var lastError: Error?
            
            for urlString in possibleURLs {
                do {
                    guard let url = URL(string: urlString) else { continue }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    
                    print("🔍 Loading all courses from: \(urlString)")
                    
                    let (data, response) = try await session.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continue
                    }
                    
                    print("📡 Response Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 404 {
                        continue // Try next URL
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        lastError = APIError.serverError(httpResponse.statusCode)
                        continue
                    }
                    
                    // Try to decode response
                    do {
                        let searchResponse = try JSONDecoder().decode(GolfCourseSearchResponse.self, from: data)
                        allCourses = searchResponse.courses
                        isLoadingAll = false
                        return // Success!
                    } catch {
                        // Try alternative formats
                        do {
                            let altResponse = try JSONDecoder().decode(AlternativeSearchResponse.self, from: data)
                            allCourses = altResponse.data
                            isLoadingAll = false
                            return // Success!
                        } catch {
                            do {
                                let courses = try JSONDecoder().decode([CourseSearchResult].self, from: data)
                                allCourses = courses
                                isLoadingAll = false
                                return // Success!
                            } catch {
                                lastError = error
                            }
                        }
                    }
                    
                } catch {
                    print("❌ Network error for \(urlString): \(error)")
                    lastError = error
                }
            }
            
            // If API fails, load mock data
            loadMockCourses()
            
        } catch {
            searchError = "Fehler beim Laden: \(error.localizedDescription)"
            loadMockCourses()
        }
        
        isLoadingAll = false
    }
    
    // MARK: - Create New Course
    
    func createNewCourse(name: String, location: String, country: String, holes: Int) async throws -> CourseSearchResult {
        // Try to create via API first
        do {
            let newCourse = CourseSearchResult(
                id: Int.random(in: 1000...9999),
                name: name,
                location: location,
                country: country,
                totalHoles: holes
            )
            
            // Add to local list immediately for better UX
            allCourses.insert(newCourse, at: 0)
            
            // TODO: Implement API creation when endpoint is available
            // For now, just return the mock course
            return newCourse
            
        } catch {
            throw error
        }
    }
    
    // MARK: - Mock Data
    
    private func loadMockCourses() {
        allCourses = [
            CourseSearchResult(id: 1, name: "Golf Club Gut Häusern", location: "München", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 2, name: "Golfclub München Eichenried", location: "München", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 3, name: "Golf & Country Club München-Riem", location: "München", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 4, name: "Golfclub Bad Abbach", location: "Bad Abbach", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 5, name: "Golf Resort Bad Griesbach", location: "Bad Griesbach", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 6, name: "Golfclub Schloss Egmating", location: "Egmating", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 7, name: "Golf Club Starnberg", location: "Starnberg", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 8, name: "Golfclub Dachau", location: "Dachau", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 9, name: "Golf Club Erding", location: "Erding", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 10, name: "Golfplatz Holledau", location: "Holledau", country: "Deutschland", totalHoles: 9),
            CourseSearchResult(id: 11, name: "Golf Club München Nord", location: "München", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 12, name: "Golf Resort Achensee", location: "Achensee", country: "Österreich", totalHoles: 18),
            CourseSearchResult(id: 13, name: "Golfclub Ammersee", location: "Herrsching", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 14, name: "Golf Club Feldafing", location: "Feldafing", country: "Deutschland", totalHoles: 18),
            CourseSearchResult(id: 15, name: "Golfanlage Gut Rieden", location: "Rieden", country: "Deutschland", totalHoles: 9)
        ]
    }
    
    // MARK: - Helper Methods
    
    func clearSearch() {
        searchResults = []
        searchError = nil
        isSearching = false
    }
    
    // Test API connectivity and discover endpoints
    func testAPIConnectivity() async {
        let testEndpoints = [
            "\(baseURL)",
            "\(baseURL)/api",
            "\(baseURL)/api/v1",
            "\(baseURL)/health",
            "\(baseURL)/status"
        ]
        
        for endpoint in testEndpoints {
            do {
                guard let url = URL(string: endpoint) else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await session.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ \(endpoint) -> Status: \(httpResponse.statusCode)")
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   Response: \(responseString.prefix(100))...")
                    }
                }
            } catch {
                print("❌ \(endpoint) -> Error: \(error)")
            }
        }
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .invalidResponse:
            return "Ungültige Antwort vom Server"
        case .serverError(let code):
            return "Server Fehler: \(code)"
        case .decodingError:
            return "Fehler beim Dekodieren der Daten"
        }
    }
} 