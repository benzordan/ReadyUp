//
//  DrillSession.swift
//  ReadyUp
//

import Foundation

enum DrillStepResult: Equatable {
    case completed(points: Int)
    case failed
    case skipped
}

// Progress through one drill. Keyed by mission id rather than holding Mission
// instances so this stays a pure value type with no SwiftData coupling, and can
// be unit-tested with three string literals.
struct DrillSession: Equatable {
    let missionIDs: [String]
    private(set) var currentIndex: Int
    private(set) var results: [String: DrillStepResult]

    init(missionIDs: [String]) {
        self.missionIDs = missionIDs
        self.currentIndex = 0
        self.results = [:]
    }

    var currentMissionID: String? {
        guard missionIDs.indices.contains(currentIndex) else { return nil }
        return missionIDs[currentIndex]
    }

    var isFinished: Bool { currentIndex >= missionIDs.count }

    var stepNumber: Int { min(currentIndex + 1, missionIDs.count) }

    var totalSteps: Int { missionIDs.count }

    var completedCount: Int {
        results.values.count { if case .completed = $0 { true } else { false } }
    }

    var pointsEarned: Int {
        results.values.reduce(0) { total, result in
            if case .completed(let points) = result { return total + points }
            return total
        }
    }

    // ========================================
    // mutating func record(_ result: DrillStepResult, forMissionID id: String)
    // Stores the outcome of one drill step. Recording twice for the same mission overwrites, so a retry within a drill replaces rather than double-counts.
    // Returns: Nothing.
    // ========================================
    mutating func record(_ result: DrillStepResult, forMissionID id: String) {
        results[id] = result
    }

    // ========================================
    // mutating func advance()
    // Moves to the next step, stopping at one past the last so isFinished stays true rather than running off the end.
    // Returns: Nothing.
    // ========================================
    mutating func advance() {
        guard currentIndex < missionIDs.count else { return }
        currentIndex += 1
    }
}
