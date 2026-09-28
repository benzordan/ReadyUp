//
//  BadgeDefinition.swift
//  ReadyUp
//

import Foundation

enum BadgeCriteria: Equatable {
    case firstMissionCompleted
    case tierReached(PreparednessTier)
    case quizzesCompleted(count: Int)
    case tasksCompleted(count: Int)
    // Breadth across hazard areas, rewarding Flow 3.
    case allDomainsCovered
    // Maintenance: a body of completed work with nothing left to go stale.
    case noStaleMissions(minimumCompleted: Int)
    // The return visit the decay system exists to produce.
    case missionRefreshed
}

struct BadgeDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let badgeDescription: String
    let iconSystemName: String
    let criteria: BadgeCriteria
}

// Badges are milestone-based rather than one-per-mission: Hamari (2017) found
// the badge effect is robust but uneven across action types, so targets are
// tiered and selective.
enum BadgeLibrary {
    static let all: [BadgeDefinition] = [
        BadgeDefinition(
            id: "first_step",
            title: "First Step",
            badgeDescription: "Complete your first mission.",
            iconSystemName: "flag.fill",
            criteria: .firstMissionCompleted
        ),
        BadgeDefinition(
            id: "tier_prepared",
            title: "Prepared",
            badgeDescription: "Reach the Prepared tier.",
            iconSystemName: "shield.lefthalf.filled",
            criteria: .tierReached(.prepared)
        ),
        BadgeDefinition(
            id: "tier_resilient",
            title: "Resilient",
            badgeDescription: "Reach the Resilient tier.",
            iconSystemName: "shield.fill",
            criteria: .tierReached(.resilient)
        ),
        BadgeDefinition(
            id: "quiz_novice",
            title: "Quick Learner",
            badgeDescription: "Answer 5 quiz missions correctly.",
            iconSystemName: "brain.head.profile",
            criteria: .quizzesCompleted(count: 5)
        ),
        BadgeDefinition(
            id: "task_champion",
            title: "Hands On",
            badgeDescription: "Complete 5 real-world preparedness tasks.",
            iconSystemName: "checkmark.seal.fill",
            criteria: .tasksCompleted(count: 5)
        ),
        BadgeDefinition(
            id: "tier_guardian",
            title: "Guardian",
            badgeDescription: "Reach the Guardian tier.",
            iconSystemName: "shield.checkered",
            criteria: .tierReached(.guardian)
        ),
        BadgeDefinition(
            id: "domain_sweep",
            title: "All Fronts",
            badgeDescription: "Complete a mission in every hazard area.",
            iconSystemName: "square.grid.2x2.fill",
            criteria: .allDomainsCovered
        ),
        BadgeDefinition(
            id: "kept_fresh",
            title: "Held the Line",
            badgeDescription: "Keep 10 missions current with nothing gone stale.",
            iconSystemName: "sparkles",
            criteria: .noStaleMissions(minimumCompleted: 10)
        ),
        BadgeDefinition(
            id: "comeback",
            title: "Back on It",
            badgeDescription: "Refresh a mission that had gone stale.",
            iconSystemName: "arrow.clockwise.circle.fill",
            criteria: .missionRefreshed
        )
    ]
}
