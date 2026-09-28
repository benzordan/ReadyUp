//
//  PersistenceController.swift
//  ReadyUp
//

import Foundation
import SwiftData

enum PersistenceController {

    static let schema = Schema([Mission.self, PreparednessScore.self, Badge.self])

    static let sharedModelContainer: ModelContainer = makeContainer()

    // ========================================
    // static func makeContainer(inMemory: Bool = false) -> ModelContainer
    // Builds the app's ModelContainer and reconciles seed content into it. Pass inMemory for previews and tests so they never touch the on-disk store.
    // Returns: A reconciled ModelContainer, or traps if the store cannot be created since the app cannot function without persistence.
    // ========================================
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            reconcileSeedData(container: container)
            return container
        } catch {
            // Failing loudly beats silently discarding user progress. If a
            // migration ever fails in development, delete the app from the
            // simulator (xcrun simctl uninstall booted com.benzordan.ReadyUp).
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // ========================================
    // static func reconcileSeedData(container: ModelContainer)
    // Brings the store in line with the authored mission set, keyed by mission id. Overwrites authored content on existing rows, inserts missions added since install, and backfills completionCount for rows completed before that field existed. Never touches user progress and never deletes, so it is safe to run on every launch.
    // Returns: Nothing.
    // ========================================
    static func reconcileSeedData(container: ModelContainer) {
        let context = ModelContext(container)

        let existingScores = (try? context.fetch(FetchDescriptor<PreparednessScore>())) ?? []
        if existingScores.isEmpty {
            context.insert(PreparednessScore())
        }

        let existingMissions = (try? context.fetch(FetchDescriptor<Mission>())) ?? []
        var missionsByID = Dictionary(uniqueKeysWithValues: existingMissions.map { ($0.id, $0) })

        for seed in MissionSeedData.starterMissions {
            guard let existing = missionsByID[seed.id] else {
                // A mission added after this user installed the app.
                context.insert(seed)
                missionsByID[seed.id] = seed
                continue
            }

            // Authored content only. completedAt, completionCount and createdAt
            // belong to the user and are never overwritten.
            existing.title = seed.title
            existing.missionDescription = seed.missionDescription
            existing.kind = seed.kind
            existing.pointValue = seed.pointValue
            existing.domain = seed.domain
            existing.refreshIntervalDays = seed.refreshIntervalDays
            existing.sortOrder = seed.sortOrder
        }

        // Migration backfill: rows completed under the old isCompleted latch
        // carry a completedAt but default to a zero completionCount. Without
        // this they would read as never done and re-award their points.
        for mission in missionsByID.values where mission.completedAt != nil && mission.completionCount == 0 {
            mission.completionCount = 1
        }

        // Missions whose ids have been retired are deliberately left in place.
        // Deleting them would destroy the user's completion history.

        try? context.save()
    }

    #if DEBUG
    // ========================================
    // static func applyDebugStaleProgress(container: ModelContainer, asOf: Date)
    // Backdates a few mission completions so the fresh, fading and expired states are all visible immediately. Debug builds only, gated behind the -seedStaleProgress launch argument, so decay can be demonstrated without waiting months.
    // Returns: Nothing.
    // ========================================
    static func applyDebugStaleProgress(container: ModelContainer, asOf: Date) {
        let context = ModelContext(container)
        let missions = (try? context.fetch(FetchDescriptor<Mission>())) ?? []
        let missionsByID = Dictionary(uniqueKeysWithValues: missions.map { ($0.id, $0) })

        // (id, days ago) chosen against each mission's own refresh interval.
        let backdated: [(String, Double)] = [
            ("task.ready_bag", 200),            // interval 180 -> expired
            ("task.fire_safety_checklist", 140), // interval 180 -> fading
            ("quiz.emergency_number", 10)        // interval 365 -> fresh
        ]

        for (id, daysAgo) in backdated {
            guard let mission = missionsByID[id] else { continue }
            mission.completedAt = asOf.addingTimeInterval(-daysAgo * 86_400)
            mission.completionCount = max(mission.completionCount, 1)
        }

        try? context.save()
    }
    #endif
}
