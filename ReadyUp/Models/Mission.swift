//
//  Mission.swift
//  ReadyUp
//

import Foundation
import SwiftData

@Model
final class Mission {
    // Stable string id so quiz-kind missions can be matched to QuizLibrary content.
    @Attribute(.unique) var id: String
    var title: String
    // Named missionDescription to avoid colliding with CustomStringConvertible.
    var missionDescription: String
    var kind: MissionKind
    var pointValue: Int

    // Every property below carries an inline default so SwiftData's lightweight
    // migration succeeds on stores created before they existed. Without a
    // default, migration throws and PersistenceController.makeContainer traps.
    var domain: HazardDomain = HazardDomain.householdReadiness
    // How long a completion stays worth full points before it fades. Real-world
    // supplies drift, so a packed Ready Bag is not still packed a year later.
    var refreshIntervalDays: Int = 365
    // Missions are repeatable once stale, so completion is a count rather than
    // the old isCompleted latch. Reconciliation backfills this to 1 for rows
    // completed before the field existed.
    var completionCount: Int = 0
    // Authored display order. Needed as a stored column because FetchDescriptor
    // sorts on a keypath, and createdAt would place newly seeded missions last
    // on an existing install.
    var sortOrder: Int = 0

    // The most recent completion. nil means never completed.
    var completedAt: Date?
    var createdAt: Date

    var hasEverBeenCompleted: Bool { completionCount > 0 }

    init(
        id: String,
        title: String,
        missionDescription: String = "",
        kind: MissionKind,
        pointValue: Int,
        domain: HazardDomain = .householdReadiness,
        refreshIntervalDays: Int = 365,
        completionCount: Int = 0,
        sortOrder: Int = 0,
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.missionDescription = missionDescription
        self.kind = kind
        self.pointValue = pointValue
        self.domain = domain
        self.refreshIntervalDays = refreshIntervalDays
        self.completionCount = completionCount
        self.sortOrder = sortOrder
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}
