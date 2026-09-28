//
//  HazardKind.swift
//  ReadyUp
//

import Foundation

// The hazards ReadyUp can warn about live — each backed by a real NEA feed:
// rainfall for flash floods, the 24-hour PSI for haze, air temperature for
// heat. Hazards without a live signal (fire, security threats) are deliberately
// absent: they are practice domains in Prepare, and inventing a live "warning"
// for them would be fabricated data in a life-safety screen.
//
// Each kind carries its own per-tier message table, extending the report's
// requirement that every tier have its own colour, message and protective
// action. The flash-flood strings are the report's table verbatim; the haze
// boundaries and guidance follow NEA's official PSI health advisory bands.
enum HazardKind: CaseIterable {
    case flashFlood
    case haze
    case heat

    var displayName: String {
        switch self {
        case .flashFlood: "Flash Flood"
        case .haze: "Haze"
        case .heat: "Heat"
        }
    }

    // "FLASH FLOOD RISK HIGH", matching the report prototype's takeover banner.
    var takeoverHeadline: String { "\(displayName.uppercased()) RISK HIGH" }

    // The notification title's leading phrase: "Flash flood risk — Bedok".
    var warningName: String {
        switch self {
        case .flashFlood: "Flash flood risk"
        case .haze: "Haze risk"
        case .heat: "Heat risk"
        }
    }

    func situation(at tier: AlertTier) -> String {
        switch (self, tier) {
        case (_, .low): "All clear."
        case (.flashFlood, .moderate): "Heavy rain developing."
        case (.flashFlood, .high): "Flash flood risk."
        case (.haze, .moderate): "Haze is building."
        case (.haze, .high): "Hazardous haze levels."
        case (.heat, .moderate): "Unusually hot today."
        case (.heat, .high): "Extreme heat."
        }
    }

    func protectiveAction(at tier: AlertTier) -> String {
        switch (self, tier) {
        case (_, .low): "No action required."
        case (.flashFlood, .moderate): "Stay indoors and monitor, avoid low-lying areas."
        case (.flashFlood, .high): "Move to higher ground now, avoid underpasses and canals."
        case (.haze, .moderate): "Reduce prolonged or strenuous outdoor activity."
        case (.haze, .high): "Stay indoors with windows closed, wear an N95 mask if you must go out."
        case (.heat, .moderate): "Stay hydrated and take breaks from outdoor activity."
        case (.heat, .high): "Avoid outdoor exertion, stay in shade or indoors, and check on the vulnerable."
        }
    }
}
