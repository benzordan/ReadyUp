//
//  AppClock.swift
//  ReadyUp
//

import Foundation

// Supplies "now" to anything that computes freshness, so decay can be observed
// without waiting months. Launching with `-simulateDaysOffset 200` shifts the
// app's idea of today forward 200 days, which turns a mission completed a
// minute ago into an expired one.
struct AppClock {
    var now: () -> Date

    static let live = AppClock(now: { .now })

    // ========================================
    // static func fromLaunchArguments(_ arguments: [String]) -> AppClock
    // Builds a clock shifted by the day offset following -simulateDaysOffset, if present.
    // Returns: A shifted clock when a valid offset is supplied, otherwise the live clock.
    // ========================================
    static func fromLaunchArguments(_ arguments: [String]) -> AppClock {
        guard let flagIndex = arguments.firstIndex(of: "-simulateDaysOffset") else { return .live }

        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex,
              let offsetDays = Double(arguments[valueIndex]) else { return .live }

        let offsetSeconds = offsetDays * 86_400
        return AppClock(now: { Date.now.addingTimeInterval(offsetSeconds) })
    }
}
