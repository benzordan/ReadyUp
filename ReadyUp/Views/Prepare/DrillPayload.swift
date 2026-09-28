//
//  DrillPayload.swift
//  ReadyUp
//

import Foundation

// Wrapper so a drill's mission list can drive .fullScreenCover(item:).
// Shared by the Prepare tab and the Home dashboard, which both start drills.
struct DrillPayload: Identifiable {
    let missions: [Mission]

    var id: String { missions.map(\.id).joined(separator: "|") }
}
