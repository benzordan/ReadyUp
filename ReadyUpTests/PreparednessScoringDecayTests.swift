//
//  PreparednessScoringDecayTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct PreparednessScoringDecayTests {

    private let reference = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeMission(
        id: String,
        points: Int = 30,
        intervalDays: Int = 180,
        domain: HazardDomain = .householdReadiness,
        completedDaysAgo: Double?
    ) -> Mission {
        Mission(
            id: id,
            title: id,
            kind: .task,
            pointValue: points,
            domain: domain,
            refreshIntervalDays: intervalDays,
            completionCount: completedDaysAgo == nil ? 0 : 1,
            completedAt: completedDaysAgo.map { reference.addingTimeInterval(-$0 * 86_400) }
        )
    }

    @Test func currentPointsSumsDecayedContributions() {
        let missions = [
            makeMission(id: "a", completedDaysAgo: 0),     // fresh, 30
            makeMission(id: "b", completedDaysAgo: 135),   // half faded, 15
            makeMission(id: "c", completedDaysAgo: 200),   // expired, 0
            makeMission(id: "d", completedDaysAgo: nil)    // never done, 0
        ]

        #expect(PreparednessScoring.currentPoints(missions: missions, asOf: reference) == 45)
    }

    @Test func maximumPointsIgnoresDecay() {
        let missions = [
            makeMission(id: "a", completedDaysAgo: 200),
            makeMission(id: "b", completedDaysAgo: nil)
        ]

        #expect(PreparednessScoring.maximumPoints(missions: missions) == 60)
    }

    @Test func refreshNeededCountsFadingAndExpiredOnly() {
        let missions = [
            makeMission(id: "fresh", completedDaysAgo: 10),
            makeMission(id: "fading", completedDaysAgo: 135),
            makeMission(id: "expired", completedDaysAgo: 400),
            makeMission(id: "never", completedDaysAgo: nil)
        ]

        // A never-completed mission was never fresh, so it is not a refresh.
        #expect(PreparednessScoring.refreshNeededCount(missions: missions, asOf: reference) == 2)
    }

    @Test func fullyFreshSeedSetScoresMaximumAndReachesGuardian() {
        let missions = MissionSeedData.starterMissions
        for mission in missions {
            mission.completionCount = 1
            mission.completedAt = reference
        }

        let points = PreparednessScoring.currentPoints(missions: missions, asOf: reference)
        #expect(points == 660)
        #expect(PreparednessScoring.tier(for: points) == .guardian)
    }

    // Standing guard: if the seed set is ever edited, Guardian must stay reachable.
    @Test func seedCeilingClearsTheGuardianThreshold() {
        let ceiling = PreparednessScoring.maximumPoints(missions: MissionSeedData.starterMissions)
        #expect(ceiling >= PreparednessTier.guardian.minimumPoints)
    }

    @Test func fullyExpiredSeedSetScoresZeroAndFallsToStarter() {
        let missions = MissionSeedData.starterMissions
        for mission in missions {
            mission.completionCount = 1
            // Older than the longest interval in the seed set.
            mission.completedAt = reference.addingTimeInterval(-500 * 86_400)
        }

        let points = PreparednessScoring.currentPoints(missions: missions, asOf: reference)
        #expect(points == 0)
        #expect(PreparednessScoring.tier(for: points) == .starter)
    }

    @Test func domainSummaryCountsAddUpToTotal() {
        let missions = [
            makeMission(id: "a", domain: .fireSafety, completedDaysAgo: 10),
            makeMission(id: "b", domain: .fireSafety, completedDaysAgo: 400),
            makeMission(id: "c", domain: .fireSafety, completedDaysAgo: nil),
            makeMission(id: "d", domain: .firstAid, completedDaysAgo: 10)
        ]

        let summary = HazardDomainSummarizer.summary(for: .fireSafety, missions: missions, asOf: reference)

        #expect(summary.totalMissions == 3)
        #expect(summary.freshMissions == 1)
        #expect(summary.needsRefreshMissions == 1)
        #expect(summary.points == 30)
        #expect(summary.maxPoints == 90)
    }

    @Test func summariesCoverEveryDomain() {
        let summaries = HazardDomainSummarizer.summaries(
            missions: MissionSeedData.starterMissions,
            asOf: reference
        )

        #expect(summaries.count == HazardDomain.allCases.count)
        #expect(summaries.map(\.domain) == HazardDomain.allCases)
    }

    @Test func emptyDomainSummaryHasZeroFractionAndDoesNotDivideByZero() {
        let summary = HazardDomainSummarizer.summary(for: .securityThreats, missions: [], asOf: reference)

        #expect(summary.totalMissions == 0)
        #expect(summary.fractionOfMax == 0)
    }
}
