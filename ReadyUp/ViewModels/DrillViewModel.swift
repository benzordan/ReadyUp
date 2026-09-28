//
//  DrillViewModel.swift
//  ReadyUp
//

import Foundation
import Observation

// Drives one drill run.
//
// Deliberately owns no ModelContext. Completion, scoring and badge unlocking
// all stay in PrepareViewModel, and results are reported out through a closure
// the same way QuizViewModel already does. That keeps a single write path for
// progress and lets this be unit-tested with plain Mission values.
@MainActor
@Observable
final class DrillViewModel {

    private(set) var missions: [Mission]
    private(set) var session: DrillSession

    private let soundService: SoundServicing
    private let onMissionResolved: (Mission, Bool) -> Void

    init(
        missions: [Mission],
        soundService: SoundServicing = SystemSoundService(),
        onMissionResolved: @escaping (Mission, Bool) -> Void
    ) {
        self.missions = missions
        self.session = DrillSession(missionIDs: missions.map(\.id))
        self.soundService = soundService
        self.onMissionResolved = onMissionResolved
    }

    var currentMission: Mission? {
        guard let id = session.currentMissionID else { return nil }
        return missions.first { $0.id == id }
    }

    var currentQuestion: QuizQuestion? {
        guard let mission = currentMission, mission.kind == .quiz else { return nil }
        return QuizLibrary.question(forMissionID: mission.id)
    }

    var stepNumber: Int { session.stepNumber }
    var totalSteps: Int { session.totalSteps }
    var isFinished: Bool { session.isFinished }
    var pointsEarned: Int { session.pointsEarned }

    var progressFraction: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(session.currentIndex) / Double(totalSteps)
    }

    // ========================================
    // func result(forMissionID id: String) -> DrillStepResult?
    // Looks up how one step of this drill went, for the summary screen.
    // Returns: The recorded result, or nil if that step has not been resolved.
    // ========================================
    func result(forMissionID id: String) -> DrillStepResult? {
        session.results[id]
    }

    // ========================================
    // func completeCurrentTask()
    // Records the current task step as done and reports it out for scoring. No-op if the current step is not a task.
    // Returns: Nothing.
    // ========================================
    func completeCurrentTask() {
        guard let mission = currentMission, mission.kind == .task else { return }
        session.record(.completed(points: mission.pointValue), forMissionID: mission.id)
        onMissionResolved(mission, true)
    }

    // ========================================
    // func recordCurrentQuizAnswer(wasCorrect: Bool)
    // Records the current quiz step's outcome and reports it out. A wrong answer scores nothing and leaves the mission claimable later.
    // Returns: Nothing.
    // ========================================
    func recordCurrentQuizAnswer(wasCorrect: Bool) {
        guard let mission = currentMission, mission.kind == .quiz else { return }
        session.record(
            wasCorrect ? .completed(points: mission.pointValue) : .failed,
            forMissionID: mission.id
        )
        onMissionResolved(mission, wasCorrect)
    }

    // ========================================
    // func skipCurrent()
    // Marks the current step skipped and moves on without awarding anything.
    // Returns: Nothing.
    // ========================================
    func skipCurrent() {
        guard let mission = currentMission else { return }
        session.record(.skipped, forMissionID: mission.id)
        advance()
    }

    // ========================================
    // func advance()
    // Moves to the next drill step, playing the completion sound once the last one is resolved.
    // Returns: Nothing.
    // ========================================
    func advance() {
        session.advance()
        if session.isFinished && session.completedCount > 0 {
            soundService.playBadgeUnlocked()
        }
    }
}
