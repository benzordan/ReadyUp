//
//  DrillPickerTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

// Assertions here are deliberately property-based rather than exact-output
// snapshots: Array.shuffled(using:) is not guaranteed stable across Swift
// toolchain versions, so pinning specific ids would be a latent flake.
struct DrillPickerTests {

    private let reference = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeMission(
        id: String,
        state: MissionFreshnessState,
        domain: HazardDomain = .householdReadiness
    ) -> Mission {
        let interval = 180
        let daysAgo: Double? = switch state {
        case .neverCompleted: nil
        case .fresh: 10
        case .fading: 135
        case .expired: 400
        }

        return Mission(
            id: id,
            title: id,
            kind: .task,
            pointValue: 30,
            domain: domain,
            refreshIntervalDays: interval,
            completionCount: daysAgo == nil ? 0 : 1,
            completedAt: daysAgo.map { reference.addingTimeInterval(-$0 * 86_400) }
        )
    }

    private func makeMissions(
        count: Int,
        state: MissionFreshnessState,
        prefix: String,
        domain: HazardDomain = .householdReadiness
    ) -> [Mission] {
        (0..<count).map { makeMission(id: "\(prefix).\($0)", state: state, domain: domain) }
    }

    private func pick(_ missions: [Mission], seed: UInt64 = 42, count: Int = 3) -> [Mission] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return DrillPicker.pick(from: missions, count: count, asOf: reference, using: &generator)
    }

    @Test func returnsExactlyThreeWhenEnoughCandidates() {
        #expect(pick(makeMissions(count: 10, state: .neverCompleted, prefix: "n")).count == 3)
    }

    @Test func returnsAllWhenFewerThanThreeExist() {
        let picked = pick(makeMissions(count: 2, state: .neverCompleted, prefix: "n"))
        #expect(picked.count == 2)
        #expect(Set(picked.map(\.id)).count == 2)
    }

    @Test func returnsEmptyForEmptyInput() {
        #expect(pick([]).isEmpty)
    }

    @Test func returnsEmptyForNonPositiveCount() {
        let missions = makeMissions(count: 10, state: .neverCompleted, prefix: "n")
        #expect(pick(missions, count: 0).isEmpty)
        #expect(pick(missions, count: -1).isEmpty)
    }

    @Test func picksAreDistinct() {
        let picked = pick(makeMissions(count: 10, state: .neverCompleted, prefix: "n"))
        #expect(Set(picked.map(\.id)).count == picked.count)
    }

    // MARK: - Priority ordering

    @Test func expiredOutranksFresh() {
        let missions = makeMissions(count: 5, state: .expired, prefix: "exp")
            + makeMissions(count: 20, state: .fresh, prefix: "fresh")
        #expect(pick(missions).allSatisfy { $0.id.hasPrefix("exp") })
    }

    @Test func expiredOutranksNeverCompleted() {
        let missions = makeMissions(count: 5, state: .expired, prefix: "exp")
            + makeMissions(count: 20, state: .neverCompleted, prefix: "new")
        #expect(pick(missions).allSatisfy { $0.id.hasPrefix("exp") })
    }

    @Test func neverCompletedOutranksFading() {
        let missions = makeMissions(count: 5, state: .neverCompleted, prefix: "new")
            + makeMissions(count: 20, state: .fading, prefix: "fade")
        #expect(pick(missions).allSatisfy { $0.id.hasPrefix("new") })
    }

    @Test func fadingOutranksFresh() {
        let missions = makeMissions(count: 5, state: .fading, prefix: "fade")
            + makeMissions(count: 20, state: .fresh, prefix: "fresh")
        #expect(pick(missions).allSatisfy { $0.id.hasPrefix("fade") })
    }

    @Test func fillsDownPriorityOrderWhenTopBucketIsShort() {
        let missions = makeMissions(count: 2, state: .expired, prefix: "exp")
            + makeMissions(count: 5, state: .neverCompleted, prefix: "new")
        let picked = pick(missions)

        #expect(picked.count == 3)
        #expect(picked.count { $0.id.hasPrefix("exp") } == 2)
        #expect(picked.count { $0.id.hasPrefix("new") } == 1)
    }

    @Test func priorityRankingIsOrderedByUrgency() {
        #expect(DrillPicker.priority(for: .expired) < DrillPicker.priority(for: .neverCompleted))
        #expect(DrillPicker.priority(for: .neverCompleted) < DrillPicker.priority(for: .fading))
        #expect(DrillPicker.priority(for: .fading) < DrillPicker.priority(for: .fresh))
    }

    // MARK: - Domain spread

    @Test func prefersDistinctDomains() {
        let missions = HazardDomain.allCases.map {
            makeMission(id: "new.\($0.rawValue)", state: .neverCompleted, domain: $0)
        }
        let picked = pick(missions)

        #expect(Set(picked.map(\.domain)).count == 3)
    }

    @Test func fallsBackWhenOnlyOneDomainAvailable() {
        let missions = makeMissions(count: 5, state: .neverCompleted, prefix: "new", domain: .fireSafety)
        #expect(pick(missions).count == 3)
    }

    // Never reach into a lower-priority bucket just to achieve a domain spread.
    @Test func domainSpreadNeverOverridesPriority() {
        let missions = makeMissions(count: 3, state: .expired, prefix: "exp", domain: .fireSafety)
            + makeMissions(count: 5, state: .fresh, prefix: "fresh", domain: .firstAid)
        #expect(pick(missions).allSatisfy { $0.id.hasPrefix("exp") })
    }

    // MARK: - Reroll behaviour

    // The drill is re-rolled each visit rather than persisted, so this is what
    // stops a user rerolling until the overdue work disappears.
    @Test func rerollCannotDodgeOverdueWork() {
        let missions = makeMissions(count: 5, state: .expired, prefix: "exp")
            + makeMissions(count: 25, state: .fresh, prefix: "fresh")

        for seed in UInt64(0)..<20 {
            let picked = pick(missions, seed: seed)
            #expect(picked.count == 3)
            #expect(picked.allSatisfy { $0.id.hasPrefix("exp") }, "seed \(seed) escaped overdue work")
        }
    }

    @Test func differentSeedsProduceVariety() {
        let missions = makeMissions(count: 12, state: .neverCompleted, prefix: "new")

        var seen: Set<String> = []
        for seed in UInt64(0)..<20 {
            seen.formUnion(pick(missions, seed: seed).map(\.id))
        }

        #expect(seen.count > 3, "picking looks deterministic across seeds")
    }

    @Test func seededGeneratorIsReproducible() {
        let missions = makeMissions(count: 12, state: .neverCompleted, prefix: "new")
        #expect(pick(missions, seed: 99).map(\.id) == pick(missions, seed: 99).map(\.id))
    }
}
