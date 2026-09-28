//
//  PreparednessScore.swift
//  ReadyUp
//

import Foundation
import SwiftData

// Metadata about the user's scoring history. The *live* score is no longer
// stored here: it is derived from mission freshness by PreparednessScoring, so
// readiness lapses when the user stops maintaining it.
//
// What remains is the record that decay should not erase — lifetime points
// awarded, the best live score ever reached, and when the user last acted.
@Model
final class PreparednessScore {
    @Attribute(.unique) var id: String
    // Cumulative points ever awarded, across every completion and re-completion.
    var totalPoints: Int
    // Highest live (decayed) score reached, so an achievement survives the fade.
    // Defaulted for lightweight migration of stores created before it existed.
    var peakPoints: Int = 0
    var updatedAt: Date

    init(
        id: String = "singleton",
        totalPoints: Int = 0,
        peakPoints: Int = 0,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.totalPoints = totalPoints
        self.peakPoints = peakPoints
        self.updatedAt = updatedAt
    }
}
