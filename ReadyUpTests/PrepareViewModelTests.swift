//
//  PrepareViewModelTests.swift
//  ReadyUpTests
//

import Foundation
import SwiftData
import Testing
@testable import ReadyUp

@MainActor
struct PrepareViewModelTests {

    // A fixed date so freshness never depends on when the suite runs.
    private let reference = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(
            schema: PersistenceController.schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: PersistenceController.schema,
            configurations: [configuration]
        )
        let context = ModelContext(container)
        context.insert(PreparednessScore())
        return context
    }

    private func makeViewModel(
        _ context: ModelContext,
        sound: SoundServicing = SilentSoundService(),
        at date: Date? = nil
    ) -> PrepareViewModel {
        let asOf = date ?? reference
        return PrepareViewModel(modelContext: context, soundService: sound, clock: { asOf })
    }

    private func makeTask(id: String = "task.test", intervalDays: Int = 180) -> Mission {
        Mission(
            id: id,
            title: "Task",
            missionDescription: "d",
            kind: .task,
            pointValue: 30,
            refreshIntervalDays: intervalDays
        )
    }

    private func makeQuiz(id: String = "quiz.test", intervalDays: Int = 365) -> Mission {
        Mission(
            id: id,
            title: "Quiz",
            missionDescription: "d",
            kind: .quiz,
            pointValue: 10,
            refreshIntervalDays: intervalDays
        )
    }

    @Test func completingTaskAddsPointsMarksCompleteAndPlaysSound() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask()
        context.insert(mission)
        try context.save()

        let sound = SilentSoundService()
        let viewModel = makeViewModel(context, sound: sound)
        viewModel.completeTaskMission(mission)

        #expect(mission.hasEverBeenCompleted)
        #expect(mission.completionCount == 1)
        #expect(mission.completedAt == reference)
        #expect(viewModel.currentPoints == 30)
        #expect(sound.playedEvents.contains(.missionCompleted))
    }

    @Test func completingFirstMissionUnlocksFirstStepBadgeAndPlaysUnlockSound() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask()
        context.insert(mission)
        try context.save()

        let sound = SilentSoundService()
        let viewModel = makeViewModel(context, sound: sound)
        viewModel.completeTaskMission(mission)

        #expect(viewModel.earnedBadgeIDs.contains("first_step"))
        #expect(viewModel.newlyUnlockedBadges.contains { $0.id == "first_step" })
        #expect(sound.playedEvents.contains(.badgeUnlocked))
    }

    @Test func correctQuizAnswerAddsQuizPointsOnly() throws {
        let context = try makeInMemoryContext()
        let mission = makeQuiz()
        context.insert(mission)
        try context.save()

        let viewModel = makeViewModel(context)
        viewModel.completeQuizMission(mission, wasCorrect: true)

        #expect(mission.hasEverBeenCompleted)
        #expect(viewModel.currentPoints == 10)
    }

    @Test func incorrectQuizAnswerDoesNotCompleteOrScore() throws {
        let context = try makeInMemoryContext()
        let mission = makeQuiz()
        context.insert(mission)
        try context.save()

        let sound = SilentSoundService()
        let viewModel = makeViewModel(context, sound: sound)
        viewModel.completeQuizMission(mission, wasCorrect: false)

        #expect(mission.hasEverBeenCompleted == false)
        #expect(viewModel.currentPoints == 0)
        #expect(sound.playedEvents.isEmpty)
    }

    @Test func completingFreshMissionAgainDoesNotDoubleAward() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask()
        context.insert(mission)
        try context.save()

        let viewModel = makeViewModel(context)
        viewModel.completeTaskMission(mission)
        viewModel.completeTaskMission(mission)

        #expect(viewModel.currentPoints == 30)
        #expect(mission.completionCount == 1)
    }

    @Test func taskIsWorthThreeTimesAQuiz() throws {
        let context = try makeInMemoryContext()
        let task = makeTask()
        let quiz = makeQuiz()
        context.insert(task)
        context.insert(quiz)
        try context.save()

        let viewModel = makeViewModel(context)
        viewModel.completeQuizMission(quiz, wasCorrect: true)
        let afterQuiz = viewModel.currentPoints
        viewModel.completeTaskMission(task)
        let taskAward = viewModel.currentPoints - afterQuiz

        #expect(taskAward == afterQuiz * 3)
    }

    @Test func crossingPreparedThresholdUnlocksTierBadge() throws {
        let context = try makeInMemoryContext()
        let tasks = (0..<4).map { makeTask(id: "task.\($0)") }
        tasks.forEach { context.insert($0) }
        try context.save()

        let viewModel = makeViewModel(context)
        tasks.forEach { viewModel.completeTaskMission($0) }

        #expect(viewModel.currentPoints == 120)
        #expect(viewModel.scoreProgress.tier == .prepared)
        #expect(viewModel.earnedBadgeIDs.contains("tier_prepared"))
    }

    @Test func dismissingBadgeRemovesItFromQueue() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask()
        context.insert(mission)
        try context.save()

        let viewModel = makeViewModel(context)
        viewModel.completeTaskMission(mission)
        let initialCount = viewModel.newlyUnlockedBadges.count
        viewModel.dismissNewlyUnlockedBadges()

        #expect(viewModel.newlyUnlockedBadges.count == initialCount - 1)
    }

    @Test func seededMissionsLoadWithExpectedPointTotal() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let viewModel = makeViewModel(ModelContext(container))

        #expect(viewModel.missions.count == 30)
        #expect(viewModel.missions.count { $0.kind == .task } == 18)
        #expect(viewModel.missions.count { $0.kind == .quiz } == 12)
        #expect(viewModel.missions.reduce(0) { $0 + $1.pointValue } == 660)
        // Nothing completed yet, so the live score starts at zero.
        #expect(viewModel.currentPoints == 0)
    }

    // MARK: - Decay

    @Test func scoreDecaysAsTimeAdvances() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask(intervalDays: 180)
        context.insert(mission)
        try context.save()

        makeViewModel(context).completeTaskMission(mission)

        let atCompletion = makeViewModel(context)
        let midFade = makeViewModel(context, at: reference.addingTimeInterval(135 * 86_400))
        let expired = makeViewModel(context, at: reference.addingTimeInterval(180 * 86_400))

        #expect(atCompletion.currentPoints == 30)
        #expect(midFade.currentPoints == 15)
        #expect(expired.currentPoints == 0)
    }

    @Test func expiredMissionCanBeRecompletedForFullValue() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask(intervalDays: 180)
        context.insert(mission)
        try context.save()

        makeViewModel(context).completeTaskMission(mission)

        let later = reference.addingTimeInterval(200 * 86_400)
        let viewModel = makeViewModel(context, at: later)
        #expect(viewModel.currentPoints == 0)

        viewModel.completeTaskMission(mission)

        #expect(viewModel.currentPoints == 30)
        #expect(mission.completionCount == 2)
        #expect(mission.completedAt == later)
    }

    @Test func recompletionUnlocksComebackBadge() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask(intervalDays: 180)
        context.insert(mission)
        try context.save()

        makeViewModel(context).completeTaskMission(mission)

        let viewModel = makeViewModel(context, at: reference.addingTimeInterval(200 * 86_400))
        viewModel.completeTaskMission(mission)

        #expect(viewModel.earnedBadgeIDs.contains("comeback"))
    }

    @Test func peakPointsRetainsHighWaterMarkAfterDecay() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask(intervalDays: 180)
        context.insert(mission)
        try context.save()

        makeViewModel(context).completeTaskMission(mission)

        let afterExpiry = makeViewModel(context, at: reference.addingTimeInterval(200 * 86_400))
        #expect(afterExpiry.currentPoints == 0)
        #expect(afterExpiry.peakPoints == 30)
    }

    @Test func lifetimePointsKeepAccumulatingAcrossRecompletions() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask(intervalDays: 180)
        context.insert(mission)
        try context.save()

        makeViewModel(context).completeTaskMission(mission)
        let viewModel = makeViewModel(context, at: reference.addingTimeInterval(200 * 86_400))
        viewModel.completeTaskMission(mission)

        #expect(viewModel.scoreRecord.totalPoints == 60)
    }

    @Test func canCompleteRejectsFreshButAllowsFading() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask(intervalDays: 180)
        context.insert(mission)
        try context.save()

        makeViewModel(context).completeTaskMission(mission)

        #expect(makeViewModel(context).canComplete(mission) == false)
        let fading = makeViewModel(context, at: reference.addingTimeInterval(135 * 86_400))
        #expect(fading.canComplete(mission))
    }

    @Test func missionsNeedingRefreshCountReflectsDecay() throws {
        let context = try makeInMemoryContext()
        let mission = makeTask(intervalDays: 180)
        context.insert(mission)
        try context.save()

        makeViewModel(context).completeTaskMission(mission)

        #expect(makeViewModel(context).missionsNeedingRefreshCount == 0)
        let later = makeViewModel(context, at: reference.addingTimeInterval(200 * 86_400))
        #expect(later.missionsNeedingRefreshCount == 1)
    }

    // MARK: - Domains and drills

    @Test func missionsInDomainFiltersBySeededDomain() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let viewModel = makeViewModel(ModelContext(container))

        let fire = viewModel.missions(in: .fireSafety)
        #expect(fire.allSatisfy { $0.domain == .fireSafety })
        #expect(fire.count >= 1)
    }

    @Test func domainSummariesCoverEveryDomain() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let viewModel = makeViewModel(ModelContext(container))

        #expect(viewModel.domainSummaries.count == HazardDomain.allCases.count)
    }

    @Test func makeDrillReturnsThreeMissionsFromSeedSet() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let viewModel = makeViewModel(ModelContext(container))

        var generator = SeededRandomNumberGenerator(seed: 7)
        let drill = viewModel.makeDrill(using: &generator)

        #expect(drill.count == 3)
        #expect(Set(drill.map(\.id)).count == 3)
    }
}
