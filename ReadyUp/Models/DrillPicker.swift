//
//  DrillPicker.swift
//  ReadyUp
//

import Foundation

// Chooses the missions for a drill.
//
// Picking is weighted rather than uniform: a drill that spent all three slots
// on things already fresh would waste the user's time while something overdue
// sat ignored. Buckets are ordered by how much they need attention, shuffled
// within each bucket so drills still feel varied, then filled top-down.
//
// Expired outranks never-completed deliberately. An expired mission is
// readiness the user had and lost, it is actively dragging the score down, and
// redoing something already done once is cheap. New missions are new work.
//
// A drill is re-rolled on every visit rather than persisted, so weighting also
// does the job a fixed daily drill would: with three or more expired missions
// every possible roll returns expired ones, and the only way to stop seeing
// them is to actually do them.
enum DrillPicker {

    static let drillSize = 3

    // ========================================
    // static func priority(for state: MissionFreshnessState) -> Int
    // Ranks a freshness state by how urgently it belongs in a drill, lowest first. Pure function, unit-tested; this ordering is the whole weighting policy.
    // Returns: 0 for expired through 3 for fresh.
    // ========================================
    static func priority(for state: MissionFreshnessState) -> Int {
        switch state {
        case .expired: 0
        case .neverCompleted: 1
        case .fading: 2
        case .fresh: 3
        }
    }

    // ========================================
    // static func pick(from missions: [Mission], count: Int = drillSize, asOf date: Date, using generator: inout some RandomNumberGenerator) -> [Mission]
    // Picks a drill's worth of missions, taking the most-overdue bucket first and preferring a spread of hazard areas within a bucket. Pure function taking an injected generator, so tests are deterministic; never returns duplicates and returns fewer than requested when fewer exist.
    // Returns: Up to `count` distinct missions in priority order, or an empty array for empty input or a non-positive count.
    // ========================================
    static func pick(
        from missions: [Mission],
        count: Int = drillSize,
        asOf date: Date,
        using generator: inout some RandomNumberGenerator
    ) -> [Mission] {
        guard count > 0, !missions.isEmpty else { return [] }

        var buckets: [Int: [Mission]] = [:]
        for mission in missions {
            let state = PreparednessFreshness.state(of: mission, asOf: date)
            buckets[priority(for: state), default: []].append(mission)
        }

        var picked: [Mission] = []
        var pickedDomains: Set<HazardDomain> = []

        for rank in buckets.keys.sorted() {
            guard picked.count < count else { break }
            // Shuffle within the bucket only. Priority between buckets stays
            // deterministic; variety comes from the ordering inside one.
            var candidates = (buckets[rank] ?? []).shuffled(using: &generator)

            while picked.count < count, !candidates.isEmpty {
                // Prefer an unrepresented hazard area, but never reach into a
                // lower-priority bucket just to achieve a spread.
                let index = candidates.firstIndex { !pickedDomains.contains($0.domain) } ?? 0
                let mission = candidates.remove(at: index)
                picked.append(mission)
                pickedDomains.insert(mission.domain)
            }
        }

        return picked
    }
}
