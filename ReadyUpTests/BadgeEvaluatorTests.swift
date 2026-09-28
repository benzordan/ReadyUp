//
//  BadgeEvaluatorTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct BadgeEvaluatorTests {

    private let reference = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeCompletedMission(
        id: String,
        kind: MissionKind,
        domain: HazardDomain = .householdReadiness,
        completedDaysAgo: Double = 0,
        completionCount: Int = 1
    ) -> Mission {
        Mission(
            id: id,
            title: "Test",
            missionDescription: "Test",
            kind: kind,
            pointValue: kind == .task ? 30 : 10,
            domain: domain,
            refreshIntervalDays: 180,
            completionCount: completionCount,
            completedAt: reference.addingTimeInterval(-completedDaysAgo * 86_400)
        )
    }

    private func evaluate(
        _ missions: [Mission],
        points: Int,
        earned: Set<String> = []
    ) -> [BadgeDefinition] {
        BadgeEvaluator.evaluate(
            missions: missions,
            currentPoints: points,
            asOf: reference,
            alreadyEarnedBadgeIDs: earned
        )
    }

    @Test func firstCompletedMissionUnlocksFirstStepBadge() {
        let unlocked = evaluate([makeCompletedMission(id: "task.a", kind: .task)], points: 30)
        #expect(unlocked.contains { $0.id == "first_step" })
    }

    @Test func noCompletedMissionsUnlocksNothing() {
        #expect(evaluate([], points: 0).isEmpty)
    }

    @Test func alreadyEarnedBadgeIsNotReturnedAgain() {
        let unlocked = evaluate(
            [makeCompletedMission(id: "task.a", kind: .task)],
            points: 30,
            earned: ["first_step"]
        )
        #expect(!unlocked.contains { $0.id == "first_step" })
    }

    @Test func reachingPreparedTierUnlocksPreparedButNotResilient() {
        let unlocked = evaluate([makeCompletedMission(id: "task.a", kind: .task)], points: 100)
        #expect(unlocked.contains { $0.id == "tier_prepared" })
        #expect(!unlocked.contains { $0.id == "tier_resilient" })
    }

    @Test func reachingResilientTierUnlocksBothTierBadges() {
        let unlocked = evaluate([makeCompletedMission(id: "task.a", kind: .task)], points: 250)
        #expect(unlocked.contains { $0.id == "tier_prepared" })
        #expect(unlocked.contains { $0.id == "tier_resilient" })
    }

    @Test func reachingGuardianTierUnlocksGuardianBadge() {
        let unlocked = evaluate([makeCompletedMission(id: "task.a", kind: .task)], points: 500)
        #expect(unlocked.contains { $0.id == "tier_guardian" })
    }

    @Test func fiveCompletedQuizzesUnlocksQuizBadge() {
        let quizzes = (0..<5).map { makeCompletedMission(id: "quiz.\($0)", kind: .quiz) }
        #expect(evaluate(quizzes, points: 50).contains { $0.id == "quiz_novice" })
    }

    @Test func fourCompletedQuizzesDoesNotUnlockQuizBadge() {
        let quizzes = (0..<4).map { makeCompletedMission(id: "quiz.\($0)", kind: .quiz) }
        #expect(!evaluate(quizzes, points: 40).contains { $0.id == "quiz_novice" })
    }

    @Test func completedQuizzesDoNotCountTowardTaskBadge() {
        let quizzes = (0..<5).map { makeCompletedMission(id: "quiz.\($0)", kind: .quiz) }
        #expect(!evaluate(quizzes, points: 50).contains { $0.id == "task_champion" })
    }

    @Test func fiveCompletedTasksUnlocksTaskBadge() {
        let tasks = (0..<5).map { makeCompletedMission(id: "task.\($0)", kind: .task) }
        #expect(evaluate(tasks, points: 150).contains { $0.id == "task_champion" })
    }

    // MARK: - Decay-aware criteria

    @Test func completingOneMissionInEveryDomainUnlocksDomainSweep() {
        let missions = HazardDomain.allCases.map {
            makeCompletedMission(id: "task.\($0.rawValue)", kind: .task, domain: $0)
        }
        #expect(evaluate(missions, points: 180).contains { $0.id == "domain_sweep" })
    }

    @Test func missingOneDomainDoesNotUnlockDomainSweep() {
        let missions = HazardDomain.allCases.dropLast().map {
            makeCompletedMission(id: "task.\($0.rawValue)", kind: .task, domain: $0)
        }
        #expect(!evaluate(missions, points: 150).contains { $0.id == "domain_sweep" })
    }

    // Stale work counts as "ever completed" for count criteria, so an earned
    // badge can never become unearnable, but it does block the maintenance one.
    @Test func staleMissionBlocksKeptFreshBadge() {
        var missions = (0..<9).map { makeCompletedMission(id: "task.\($0)", kind: .task) }
        missions.append(makeCompletedMission(id: "task.stale", kind: .task, completedDaysAgo: 200))

        #expect(!evaluate(missions, points: 270).contains { $0.id == "kept_fresh" })
    }

    @Test func tenFreshMissionsUnlocksKeptFreshBadge() {
        let missions = (0..<10).map { makeCompletedMission(id: "task.\($0)", kind: .task) }
        #expect(evaluate(missions, points: 300).contains { $0.id == "kept_fresh" })
    }

    @Test func nineFreshMissionsDoesNotUnlockKeptFreshBadge() {
        let missions = (0..<9).map { makeCompletedMission(id: "task.\($0)", kind: .task) }
        #expect(!evaluate(missions, points: 270).contains { $0.id == "kept_fresh" })
    }

    @Test func recompletedMissionUnlocksComebackBadge() {
        let mission = makeCompletedMission(id: "task.a", kind: .task, completionCount: 2)
        #expect(evaluate([mission], points: 30).contains { $0.id == "comeback" })
    }

    @Test func singleCompletionDoesNotUnlockComebackBadge() {
        let mission = makeCompletedMission(id: "task.a", kind: .task, completionCount: 1)
        #expect(!evaluate([mission], points: 30).contains { $0.id == "comeback" })
    }

    // Decay must never revoke progress toward count-based badges.
    @Test func expiredMissionsStillCountTowardCountBadges() {
        let tasks = (0..<5).map {
            makeCompletedMission(id: "task.\($0)", kind: .task, completedDaysAgo: 400)
        }
        // Live score is zero because everything expired, but the work happened.
        #expect(evaluate(tasks, points: 0).contains { $0.id == "task_champion" })
        #expect(evaluate(tasks, points: 0).contains { $0.id == "first_step" })
    }
}
