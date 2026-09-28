//
//  PrepareViewModel.swift
//  ReadyUp
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PrepareViewModel {

    private let modelContext: ModelContext
    private let clock: () -> Date

    // Exposed so both the Prepare tab and the Home dashboard can hand it to a
    // drill without either view owning its own sound service.
    let soundService: SoundServicing

    // Stored rather than computed from clock(). A computed property reading a
    // closure creates no @Observable dependency, so the score would never
    // re-render as time passes. refresh() bumps this on scene activation.
    private(set) var asOf: Date

    private(set) var missions: [Mission] = []
    private(set) var scoreRecord: PreparednessScore = PreparednessScore()
    private(set) var earnedBadgeIDs: Set<String> = []
    private(set) var newlyUnlockedBadges: [BadgeDefinition] = []

    // The live score: derived from mission freshness, not a stored total.
    var currentPoints: Int {
        PreparednessScoring.currentPoints(missions: missions, asOf: asOf)
    }

    var scoreProgress: ScoreProgress {
        PreparednessScoring.progress(forPoints: currentPoints)
    }

    var missionsNeedingRefreshCount: Int {
        PreparednessScoring.refreshNeededCount(missions: missions, asOf: asOf)
    }

    var domainSummaries: [HazardDomainSummary] {
        HazardDomainSummarizer.summaries(missions: missions, asOf: asOf)
    }

    var peakPoints: Int { scoreRecord.peakPoints }

    init(
        modelContext: ModelContext,
        soundService: SoundServicing = SystemSoundService(),
        clock: @escaping () -> Date = { Date.now }
    ) {
        self.modelContext = modelContext
        self.soundService = soundService
        self.clock = clock
        self.asOf = clock()
        loadData()
    }

    // ========================================
    // func refresh()
    // Re-reads the clock and reloads from the store. Called when the app becomes active so a score that decayed while the app was backgrounded is reflected on return.
    // Returns: Nothing.
    // ========================================
    func refresh() {
        asOf = clock()
        loadData()
    }

    // ========================================
    // func loadData()
    // Refreshes missions, the preparedness score record and earned badges from the persistent store, in authored display order.
    // Returns: Nothing.
    // ========================================
    func loadData() {
        let missionDescriptor = FetchDescriptor<Mission>(sortBy: [SortDescriptor(\.sortOrder)])
        missions = (try? modelContext.fetch(missionDescriptor)) ?? []

        if let existingScore = (try? modelContext.fetch(FetchDescriptor<PreparednessScore>()))?.first {
            scoreRecord = existingScore
        }

        let earnedBadges = (try? modelContext.fetch(FetchDescriptor<Badge>())) ?? []
        earnedBadgeIDs = Set(earnedBadges.map(\.id))
    }

    // ========================================
    // func missions(in domain: HazardDomain) -> [Mission]
    // The missions belonging to one hazard area, in authored order, for the domain detail screen.
    // Returns: Every mission assigned to that domain.
    // ========================================
    func missions(in domain: HazardDomain) -> [Mission] {
        missions.filter { $0.domain == domain }
    }

    // ========================================
    // func freshness(of mission: Mission) -> MissionFreshness
    // The mission's freshness at this view model's current date, so rows never recompute it against a different clock than the score.
    // Returns: The MissionFreshness for that mission.
    // ========================================
    func freshness(of mission: Mission) -> MissionFreshness {
        PreparednessFreshness.freshness(of: mission, asOf: asOf)
    }

    // ========================================
    // func canComplete(_ mission: Mission) -> Bool
    // Whether a mission is claimable right now. A still-fresh mission is not, which is what stops points being claimed twice; once it starts fading it becomes available again for full value.
    // Returns: True unless the mission is currently fresh.
    // ========================================
    func canComplete(_ mission: Mission) -> Bool {
        PreparednessFreshness.state(of: mission, asOf: asOf).isActionable
    }

    // ========================================
    // func makeDrill(using generator: inout some RandomNumberGenerator) -> [Mission]
    // Picks the missions for a drill, weighted toward whatever most needs doing. Takes the generator so tests can drive it deterministically.
    // Returns: Up to three missions, fewest possible still-fresh ones.
    // ========================================
    func makeDrill(using generator: inout some RandomNumberGenerator) -> [Mission] {
        DrillPicker.pick(from: missions, asOf: asOf, using: &generator)
    }

    // ========================================
    // func makeDrill() -> [Mission]
    // Convenience for the app, which wants a genuinely random drill each visit.
    // Returns: Up to three missions picked with the system generator.
    // ========================================
    func makeDrill() -> [Mission] {
        var generator = SystemRandomNumberGenerator()
        return makeDrill(using: &generator)
    }

    // ========================================
    // func resolveDrillMission(_ mission: Mission, succeeded: Bool)
    // The single write path for a drill step's outcome, routed by mission kind. Exists because both the Prepare tab and the Home dashboard start drills, and duplicating this switch at two call sites would let the two screens drift on how a failed quiz is scored.
    // Returns: Nothing.
    // ========================================
    func resolveDrillMission(_ mission: Mission, succeeded: Bool) {
        switch mission.kind {
        case .task: completeTaskMission(mission)
        case .quiz: completeQuizMission(mission, wasCorrect: succeeded)
        }
    }

    // ========================================
    // func completeTaskMission(_ mission: Mission)
    // Marks a real-world preparedness task as done and awards its points. Ignores missions that are not tasks or are still fresh, so points can never be claimed twice for one completion.
    // Returns: Nothing.
    // ========================================
    func completeTaskMission(_ mission: Mission) {
        guard mission.kind == .task, canComplete(mission) else { return }
        recordMissionCompletion(mission)
    }

    // ========================================
    // func completeQuizMission(_ mission: Mission, wasCorrect: Bool)
    // Awards a quiz mission only when the answer was correct, leaving a wrong answer unscored so the user can retry it later.
    // Returns: Nothing.
    // ========================================
    func completeQuizMission(_ mission: Mission, wasCorrect: Bool) {
        guard mission.kind == .quiz, canComplete(mission), wasCorrect else { return }
        recordMissionCompletion(mission)
    }

    // ========================================
    // private func recordMissionCompletion(_ mission: Mission)
    // Shared completion path: stamps the completion at this view model's date rather than the wall clock so an injected clock flows through end to end, then persists, plays the reward sound and re-evaluates badges.
    // Returns: Nothing.
    // ========================================
    private func recordMissionCompletion(_ mission: Mission) {
        mission.completedAt = asOf
        mission.completionCount += 1

        // Lifetime total, kept for the record even as the live score decays.
        scoreRecord.totalPoints += mission.pointValue
        scoreRecord.updatedAt = asOf
        scoreRecord.peakPoints = max(scoreRecord.peakPoints, currentPoints)

        try? modelContext.save()

        soundService.playMissionCompleted()
        evaluateAndPersistBadges()
    }

    // ========================================
    // private func evaluateAndPersistBadges()
    // Checks whether the latest completion unlocked any badges and persists the new ones. Plays the unlock sound once per completion event rather than once per badge.
    // Returns: Nothing.
    // ========================================
    private func evaluateAndPersistBadges() {
        let newlyEarned = BadgeEvaluator.evaluate(
            missions: missions,
            currentPoints: currentPoints,
            asOf: asOf,
            alreadyEarnedBadgeIDs: earnedBadgeIDs
        )
        guard !newlyEarned.isEmpty else { return }

        for definition in newlyEarned {
            modelContext.insert(Badge(id: definition.id))
            earnedBadgeIDs.insert(definition.id)
        }
        try? modelContext.save()

        newlyUnlockedBadges.append(contentsOf: newlyEarned)
        soundService.playBadgeUnlocked()
    }

    // ========================================
    // func dismissNewlyUnlockedBadges()
    // Pops the front of the unlock queue so the next badge toast can show.
    // Returns: Nothing.
    // ========================================
    func dismissNewlyUnlockedBadges() {
        guard !newlyUnlockedBadges.isEmpty else { return }
        newlyUnlockedBadges.removeFirst()
    }
}
