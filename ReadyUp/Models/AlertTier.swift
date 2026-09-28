//
//  AlertTier.swift
//  ReadyUp
//

import SwiftUI

// The three-tier hazard classification from the report. The per-hazard message
// tables live in HazardKind; this owns what is common to every hazard — the
// severity ordering, colour and icon.
//
// This model imports SwiftUI and owns its own Color, which the rest of Models
// does not: splitting the colour into a view would put the specification in
// two places and let them drift. Color is a value type, so the tier table
// stays unit-testable.
//
// Comparable is load-bearing: RiskClassifier composes the per-hazard tiers
// with max(_:_:), which is what structurally prevents a forecast alone from
// ever escalating to .high.
enum AlertTier: Int, CaseIterable, Comparable, Identifiable {
    case low = 0
    case moderate = 1
    case high = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .moderate: "Moderate"
        case .high: "High"
        }
    }

    // Amber maps to .orange; SwiftUI has no amber. System colours already adapt
    // to dark mode and increased-contrast, so no colour assets are needed.
    var color: Color {
        switch self {
        case .low: .green
        case .moderate: .orange
        case .high: .red
        }
    }

    var iconSystemName: String {
        switch self {
        case .low: "checkmark.shield.fill"
        case .moderate: "cloud.heavyrain.fill"
        case .high: "exclamationmark.triangle.fill"
        }
    }

    static func < (lhs: AlertTier, rhs: AlertTier) -> Bool { lhs.rawValue < rhs.rawValue }
}
