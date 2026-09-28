//
//  BadgeEvaluator.swift
//  ReadyUp
//

import Foundation

enum BadgeEvaluator {

    // ========================================
    // static func evaluate(missions: [Mission], currentPoints: Int, asOf date: Date, alreadyEarnedBadgeIDs: Set<String>) -> [BadgeDefinition]
    // Works out which badges have just been earned. Count-based criteria deliberately use whether a mission was *ever* completed rather than whether it is still fresh, so decay can never make an already-earned badge unearnable; only tier and staleness criteria read the decayed state. Pure function with no ModelContext dependency, unit-tested with plain in-memory Mission instances.
    // Returns: The badge definitions newly earned by this evaluation, excluding any already held. Empty when nothing new unlocked.
    // ========================================
    static func evaluate(
        missions: [Mission],
        currentPoints: Int,
        asOf date: Date,
        alreadyEarnedBadgeIDs: Set<String>
    ) -> [BadgeDefinition] {
        let tier = PreparednessScoring.tier(for: currentPoints)
        let completed = missions.filter(\.hasEverBeenCompleted)
        let completedQuizCount = completed.count { $0.kind == .quiz }
        let completedTaskCount = completed.count { $0.kind == .task }
        let coveredDomains = Set(completed.map(\.domain))
        let hasRefreshedAMission = missions.contains { $0.completionCount >= 2 }
        let staleCount = PreparednessScoring.refreshNeededCount(missions: missions, asOf: date)

        return BadgeLibrary.all.filter { definition in
            guard !alreadyEarnedBadgeIDs.contains(definition.id) else { return false }

            switch definition.criteria {
            case .firstMissionCompleted:
                return !completed.isEmpty
            case .tierReached(let requiredTier):
                return tier >= requiredTier
            case .quizzesCompleted(let count):
                return completedQuizCount >= count
            case .tasksCompleted(let count):
                return completedTaskCount >= count
            case .allDomainsCovered:
                return coveredDomains.count == HazardDomain.allCases.count
            case .noStaleMissions(let minimumCompleted):
                return completed.count >= minimumCompleted && staleCount == 0
            case .missionRefreshed:
                return hasRefreshedAMission
            }
        }
    }
}
