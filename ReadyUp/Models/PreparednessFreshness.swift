//
//  PreparednessFreshness.swift
//  ReadyUp
//

import Foundation

enum MissionFreshnessState: String, Equatable, CaseIterable {
    case neverCompleted
    case fresh
    case fading
    case expired

    var displayName: String {
        switch self {
        case .neverCompleted: "Not done"
        case .fresh: "Fresh"
        case .fading: "Fading"
        case .expired: "Needs refresh"
        }
    }

    // Whether this mission is available to complete for points right now.
    var isActionable: Bool {
        self != .fresh
    }
}

struct MissionFreshness: Equatable {
    let state: MissionFreshnessState
    let fraction: Double
    let contributedPoints: Int
    let daysUntilExpiry: Int?
}

// Decides how much a past completion is still worth today.
//
// The curve holds full value for the first half of a mission's refresh
// interval, then fades linearly to zero across the second half. A Ready Bag
// packed last week really is fully packed, so docking points immediately would
// punish the passage of time rather than neglect, and would make the score feel
// like a leak the user can never plug. The plateau turns decay into a nudge:
// a 180-day mission holds full value to day 90, then gives a visible
// three-month ramp before it is worth nothing.
//
// Every function here is pure and takes an explicit `asOf` date, so decay is
// unit-tested against exact boundaries without waiting real time.
enum PreparednessFreshness {

    // Share of the refresh interval held at full value before fading starts.
    static let freshFraction: Double = 0.5

    private static let secondsPerDay: Double = 86_400

    // ========================================
    // static func days(from completedAt: Date, to date: Date) -> Double
    // Elapsed days as a fractional value, measured in 86,400-second days rather than calendar components so the result is pure, timezone-independent and deterministic in tests.
    // Returns: Days elapsed, negative if the completion date is in the future.
    // ========================================
    static func days(from completedAt: Date, to date: Date) -> Double {
        date.timeIntervalSince(completedAt) / secondsPerDay
    }

    // ========================================
    // static func fraction(daysSinceCompletion: Double, refreshIntervalDays: Int) -> Double
    // The hold-then-fade curve: full value through the fresh window, linear decay to zero across the rest of the interval. Pure function, unit-tested against every boundary including clock skew and a zero-length interval.
    // Returns: A value from 0.0 to 1.0 representing how much of the mission's points still count.
    // ========================================
    static func fraction(daysSinceCompletion: Double, refreshIntervalDays: Int) -> Double {
        // A non-positive interval means the mission never goes stale.
        guard refreshIntervalDays > 0 else { return 1.0 }
        // Device clock changes can put a completion in the future; treat as new.
        guard daysSinceCompletion > 0 else { return 1.0 }

        let interval = Double(refreshIntervalDays)
        let freshWindow = interval * freshFraction

        if daysSinceCompletion <= freshWindow { return 1.0 }
        if daysSinceCompletion >= interval { return 0.0 }

        let fadeWindow = interval - freshWindow
        return (interval - daysSinceCompletion) / fadeWindow
    }

    // ========================================
    // static func state(of mission: Mission, asOf date: Date) -> MissionFreshnessState
    // Classifies a mission as never completed, fresh, fading or expired. Pure function, unit-tested against tier boundaries; drives both the drill priority order and the row badge.
    // Returns: The mission's freshness state at the given date.
    // ========================================
    static func state(of mission: Mission, asOf date: Date) -> MissionFreshnessState {
        guard mission.hasEverBeenCompleted, let completedAt = mission.completedAt else {
            return .neverCompleted
        }

        let elapsed = days(from: completedAt, to: date)
        let value = fraction(daysSinceCompletion: elapsed, refreshIntervalDays: mission.refreshIntervalDays)

        if value >= 1.0 { return .fresh }
        if value <= 0.0 { return .expired }
        return .fading
    }

    // ========================================
    // static func contributedPoints(of mission: Mission, asOf date: Date) -> Int
    // How many of a mission's points still count toward the live score today. Pure function, unit-tested; this is what makes the preparedness score decay rather than accumulate forever.
    // Returns: The decayed point contribution, rounded to the nearest whole point, or 0 if never completed.
    // ========================================
    static func contributedPoints(of mission: Mission, asOf date: Date) -> Int {
        guard mission.hasEverBeenCompleted, let completedAt = mission.completedAt else { return 0 }

        let elapsed = days(from: completedAt, to: date)
        let value = fraction(daysSinceCompletion: elapsed, refreshIntervalDays: mission.refreshIntervalDays)
        return Int((Double(mission.pointValue) * value).rounded())
    }

    // ========================================
    // static func freshness(of mission: Mission, asOf date: Date) -> MissionFreshness
    // Bundles state, decayed fraction, contributed points and the countdowns a row needs, so a view can render freshness without recomputing any of it. Pure function, unit-tested.
    // Returns: A MissionFreshness describing the mission at the given date.
    // ========================================
    static func freshness(of mission: Mission, asOf date: Date) -> MissionFreshness {
        let missionState = state(of: mission, asOf: date)

        guard mission.hasEverBeenCompleted, let completedAt = mission.completedAt else {
            return MissionFreshness(
                state: .neverCompleted,
                fraction: 0,
                contributedPoints: 0,
                daysUntilExpiry: nil
            )
        }

        let elapsed = days(from: completedAt, to: date)
        let value = fraction(daysSinceCompletion: elapsed, refreshIntervalDays: mission.refreshIntervalDays)
        let interval = Double(mission.refreshIntervalDays)

        let expiryCountdown = missionState == .expired ? nil : max(0, Int((interval - elapsed).rounded()))

        return MissionFreshness(
            state: missionState,
            fraction: value,
            contributedPoints: Int((Double(mission.pointValue) * value).rounded()),
            daysUntilExpiry: expiryCountdown
        )
    }
}
