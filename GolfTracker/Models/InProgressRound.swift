//
//  InProgressRound.swift
//  GolfTracker
//
//  Created by Tim Krebs on 7/10/25.
//

import Foundation

// MARK: - In-Progress Round Models

class InProgressRound: ObservableObject {
    @Published var courseName: String = ""
    @Published var courseId: Int?
    @Published var courseLocation: String = ""
    @Published var numberOfHoles: Int = 18 {
        didSet {
            if numberOfHoles != oldValue && apiScorecard == nil {
                setupHoles()
                // Reset to first hole if current hole is beyond new hole count
                if currentHole > numberOfHoles {
                    currentHole = 1
                }
            }
        }
    }
    @Published var startDate: Date = Date()
    @Published var currentHole: Int = 1
    @Published var holes: [InProgressHoleScore] = []
    @Published var notes: String = ""
    @Published var isCompleted: Bool = false
    @Published var apiScorecard: APIScorecard?
    
    var totalPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }
    
    var totalScore: Int {
        holes.reduce(0) { $0 + ($1.strokes ?? 0) }
    }
    
    var scoreRelativeToPar: Int {
        totalScore - totalPar
    }
    
    var completedHoles: Int {
        holes.filter { $0.strokes != nil }.count
    }
    
    var isReadyToFinish: Bool {
        completedHoles == numberOfHoles && !courseName.isEmpty
    }
    
    init(courseName: String = "", numberOfHoles: Int = 18) {
        self.courseName = courseName
        self.numberOfHoles = numberOfHoles
        self.setupHoles()
    }
    
    private func setupHoles() {
        holes = []
        for holeIndex in 1...numberOfHoles {
            // Default par based on typical golf course layout
            let defaultPar: Int
            if numberOfHoles == 9 {
                // 9-hole course: mix of par 3, 4, 5
                defaultPar = [3, 4, 5, 4, 3, 4, 5, 4, 3][holeIndex-1]
            } else {
                // 18-hole course: typical layout
                defaultPar = [4, 4, 3, 5, 4, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 3, 4, 5][holeIndex-1]
            }
            
            holes.append(InProgressHoleScore(
                holeNumber: holeIndex,
                par: defaultPar
            ))
        }
    }
    
    func updateHoleScore(holeNumber: Int, strokes: Int?, putts: Int?, fairwayHit: Bool?, greenInRegulation: Bool?) {
        guard let index = holes.firstIndex(where: { $0.holeNumber == holeNumber }) else { return }
        
        holes[index].strokes = strokes
        holes[index].putts = putts
        holes[index].fairwayHit = fairwayHit
        holes[index].greenInRegulation = greenInRegulation
    }
    
    func updateHolePar(holeNumber: Int, par: Int) {
        guard let index = holes.firstIndex(where: { $0.holeNumber == holeNumber }) else { return }
        holes[index].par = par
    }
    
    func reset() {
        courseName = ""
        courseId = nil
        courseLocation = ""
        numberOfHoles = 18
        startDate = Date()
        currentHole = 1
        notes = ""
        isCompleted = false
        apiScorecard = nil
        setupHoles()
    }
    
    // Setup round from API scorecard
    func setupFromScorecard(_ scorecard: APIScorecard) {
        apiScorecard = scorecard
        courseName = scorecard.golfCourseName
        courseLocation = "\(scorecard.location), \(scorecard.country)"
        courseId = scorecard.golfCourseId
        numberOfHoles = scorecard.holes.count
        
        // Setup holes from API data
        setupHolesFromAPI(scorecard.holes)
    }
    
    private func setupHolesFromAPI(_ apiHoles: [APIScorecardHole]) {
        holes = []
        for apiHole in apiHoles.sorted(by: { $0.holeNumber < $1.holeNumber }) {
            holes.append(InProgressHoleScore(
                holeNumber: apiHole.holeNumber,
                par: apiHole.par,
                distanceMeters: apiHole.distanceMeters,
                handicap: apiHole.handicap
            ))
        }
    }
    
    // Convert to CreateRoundRequest for saving
    func toCreateRoundRequest() -> CreateRoundRequest? {
        guard isReadyToFinish else { return nil }
        
        let holeRequests = holes.compactMap { hole -> CreateHoleScoreRequest? in
            guard let strokes = hole.strokes else { return nil }
            return CreateHoleScoreRequest(
                holeNumber: hole.holeNumber,
                par: hole.par,
                strokes: strokes,
                putts: hole.putts,
                fairwayHit: hole.fairwayHit,
                greenInRegulation: hole.greenInRegulation
            )
        }
        
        return CreateRoundRequest(
            courseName: courseName,
            date: startDate,
            totalScore: totalScore,
            par: totalPar,
            holes: holeRequests,
            notes: notes.isEmpty ? nil : notes
        )
    }
}

struct InProgressHoleScore: Identifiable {
    let id = UUID()
    let holeNumber: Int
    var par: Int
    var strokes: Int?
    var putts: Int?
    var fairwayHit: Bool?
    var greenInRegulation: Bool?
    var distanceMeters: Double?
    var handicap: Int?
    
    init(holeNumber: Int, par: Int, distanceMeters: Double? = nil, handicap: Int? = nil) {
        self.holeNumber = holeNumber
        self.par = par
        self.distanceMeters = distanceMeters
        self.handicap = handicap
    }
    
    var scoreRelativeToPar: Int? {
        guard let strokes = strokes else { return nil }
        return strokes - par
    }
    
    var scoreType: HoleScoreType? {
        guard let relative = scoreRelativeToPar else { return nil }
        switch relative {
        case ...(-3): return .albatross
        case -2: return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        case 2: return .doubleBogey
        default: return .other
        }
    }
    
    var isCompleted: Bool {
        strokes != nil
    }
} 
