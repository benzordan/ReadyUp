//
//  HazardDomainSummary.swift
//  ReadyUp
//

import Foundation

struct HazardDomainSummary: Identifiable, Equatable {
    let domain: HazardDomain
    let totalMissions: Int
    let freshMissions: Int
    let needsRefreshMissions: Int
    let points: Int
    let maxPoints: Int

    var id: String { domain.rawValue }

    var fractionOfMax: Double {
        guard maxPoints > 0 else { return 0 }
        return min(max(Double(points) / Double(maxPoints), 0), 1)
    }

    // Short status line for a grid tile.
    var statusText: String {
        if totalMissions == 0 { return "No missions" }
        if needsRefreshMissions > 0 {
            return "\(needsRefreshMissions) \(needsRefreshMissions == 1 ? "needs" : "need") refreshing"
        }
        if freshMissions == totalMissions { return "All fresh" }
        return "\(freshMissions) of \(totalMissions) fresh"
    }
}

enum HazardDomainSummarizer {

    // ========================================
    // static func summary(for domain: HazardDomain, missions: [Mission], asOf date: Date) -> HazardDomainSummary
    // Rolls one hazard area's missions into the counts and decayed point total a grid tile shows. Pure function, unit-tested; keeps this arithmetic out of the view body.
    // Returns: A HazardDomainSummary for the domain at the given date.
    // ========================================
    static func summary(
        for domain: HazardDomain,
        missions: [Mission],
        asOf date: Date
    ) -> HazardDomainSummary {
        let domainMissions = missions.filter { $0.domain == domain }

        var fresh = 0
        var needsRefresh = 0

        for mission in domainMissions {
            switch PreparednessFreshness.state(of: mission, asOf: date) {
            case .fresh: fresh += 1
            case .fading, .expired: needsRefresh += 1
            case .neverCompleted: break
            }
        }

        return HazardDomainSummary(
            domain: domain,
            totalMissions: domainMissions.count,
            freshMissions: fresh,
            needsRefreshMissions: needsRefresh,
            points: PreparednessScoring.currentPoints(missions: domainMissions, asOf: date),
            maxPoints: PreparednessScoring.maximumPoints(missions: domainMissions)
        )
    }

    // ========================================
    // static func summaries(missions: [Mission], asOf date: Date) -> [HazardDomainSummary]
    // Summarises every hazard area in declaration order, so the Prepare grid always shows all six even if one has no missions yet. Pure function, unit-tested.
    // Returns: One summary per HazardDomain case, in HazardDomain.allCases order.
    // ========================================
    static func summaries(missions: [Mission], asOf date: Date) -> [HazardDomainSummary] {
        HazardDomain.allCases.map { summary(for: $0, missions: missions, asOf: date) }
    }
}
