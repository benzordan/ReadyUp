//
//  PreparednessScoring.swift
//  ReadyUp
//

import Foundation

struct ScoreProgress: Equatable {
    let tier: PreparednessTier
    let points: Int
    let pointsIntoTier: Int
    let pointsToNextTier: Int
    let fractionToNextTier: Double
    let nextTier: PreparednessTier?
}

enum PreparednessScoring {

    // ========================================
    // static func tier(for points: Int) -> PreparednessTier
    // Maps a raw point total to the highest preparedness tier the user has reached. Pure function with no SwiftData or SwiftUI dependency, unit-tested against every tier boundary.
    // Returns: The matching PreparednessTier, defaulting to .starter for zero or negative points.
    // ========================================
    static func tier(for points: Int) -> PreparednessTier {
        PreparednessTier.allCases.reversed().first { points >= $0.minimumPoints } ?? .starter
    }

    // ========================================
    // static func nextTier(after tier: PreparednessTier) -> PreparednessTier?
    // Finds the tier immediately above the given one.
    // Returns: The next PreparednessTier, or nil when already at the highest tier.
    // ========================================
    static func nextTier(after tier: PreparednessTier) -> PreparednessTier? {
        PreparednessTier(rawValue: tier.rawValue + 1)
    }

    // ========================================
    // static func progress(forPoints points: Int) -> ScoreProgress
    // Builds the full progress snapshot for a point total, including the fraction completed toward the next tier. Reward proximity is the driver here: the user always sees how close the next tier is, rather than a static point count.
    // Returns: A ScoreProgress with fractionToNextTier clamped to 0...1, and nextTier nil at the highest tier.
    // ========================================
    static func progress(forPoints points: Int) -> ScoreProgress {
        let currentTier = tier(for: points)
        let pointsIntoTier = max(0, points - currentTier.minimumPoints)

        guard let next = nextTier(after: currentTier) else {
            return ScoreProgress(
                tier: currentTier,
                points: points,
                pointsIntoTier: pointsIntoTier,
                pointsToNextTier: 0,
                fractionToNextTier: 1.0,
                nextTier: nil
            )
        }

        let span = next.minimumPoints - currentTier.minimumPoints
        let fraction = span > 0 ? Double(pointsIntoTier) / Double(span) : 1.0

        return ScoreProgress(
            tier: currentTier,
            points: points,
            pointsIntoTier: pointsIntoTier,
            pointsToNextTier: next.minimumPoints - points,
            fractionToNextTier: min(max(fraction, 0), 1),
            nextTier: next
        )
    }

    // MARK: - Freshness-aware scoring

    // ========================================
    // static func currentPoints(missions: [Mission], asOf date: Date) -> Int
    // The live preparedness score: the sum of every mission's decayed contribution today, rather than a stored running total. Pure function, unit-tested; making the score derived is what lets readiness lapse when the user stops maintaining it.
    // Returns: The total decayed points across all missions at the given date.
    // ========================================
    static func currentPoints(missions: [Mission], asOf date: Date) -> Int {
        missions.reduce(0) { total, mission in
            total + PreparednessFreshness.contributedPoints(of: mission, asOf: date)
        }
    }

    // ========================================
    // static func maximumPoints(missions: [Mission]) -> Int
    // The ceiling a user could reach with every mission simultaneously fresh. Pure function, unit-tested as a guard that the Guardian tier stays reachable if the seed set is ever edited.
    // Returns: The sum of every mission's undecayed point value.
    // ========================================
    static func maximumPoints(missions: [Mission]) -> Int {
        missions.reduce(0) { $0 + $1.pointValue }
    }

    // ========================================
    // static func progress(missions: [Mission], asOf date: Date) -> ScoreProgress
    // Tier and next-tier progress computed from the live decayed score. Pure function, unit-tested.
    // Returns: The ScoreProgress for the decayed total at the given date.
    // ========================================
    static func progress(missions: [Mission], asOf date: Date) -> ScoreProgress {
        progress(forPoints: currentPoints(missions: missions, asOf: date))
    }

    // ========================================
    // static func refreshNeededCount(missions: [Mission], asOf date: Date) -> Int
    // Counts missions that have started losing value, so the score header can name the cause of a falling score. Deliberately excludes never-completed missions: those were never fresh, so they are not something to refresh. Pure function, unit-tested.
    // Returns: The number of fading or expired missions at the given date.
    // ========================================
    static func refreshNeededCount(missions: [Mission], asOf date: Date) -> Int {
        missions.count { mission in
            let state = PreparednessFreshness.state(of: mission, asOf: date)
            return state == .fading || state == .expired
        }
    }
}
