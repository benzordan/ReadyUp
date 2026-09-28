//
//  DrillViewModelTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

@MainActor
struct DrillViewModelTests {

    private func makeTask(id: String = "task.a") -> Mission {
        Mission(id: id, title: "Task", kind: .task, pointValue: 30)
    }

    private func makeQuiz(id: String = "quiz.emergency_number") -> Mission {
        Mission(id: id, title: "Quiz", kind: .quiz, pointValue: 10)
    }

    private func makeViewModel(
        _ missions: [Mission],
        sound: SoundServicing = SilentSoundService(),
        onResolved: @escaping (Mission, Bool) -> Void = { _, _ in }
    ) -> DrillViewModel {
        DrillViewModel(missions: missions, soundService: sound, onMissionResolved: onResolved)
    }

    @Test func startsAtFirstMission() {
        let viewModel = makeViewModel([makeTask(), makeQuiz()])

        #expect(viewModel.currentMission?.id == "task.a")
        #expect(viewModel.stepNumber == 1)
        #expect(viewModel.totalSteps == 2)
        #expect(viewModel.isFinished == false)
    }

    @Test func completingTaskReportsSuccessAndScores() {
        var reported: (Mission, Bool)?
        let mission = makeTask()
        let viewModel = makeViewModel([mission]) { reported = ($0, $1) }

        viewModel.completeCurrentTask()

        #expect(reported?.0.id == "task.a")
        #expect(reported?.1 == true)
        #expect(viewModel.pointsEarned == 30)
    }

    @Test func correctQuizAnswerReportsSuccessAndScores() {
        var reported: (Mission, Bool)?
        let viewModel = makeViewModel([makeQuiz()]) { reported = ($0, $1) }

        viewModel.recordCurrentQuizAnswer(wasCorrect: true)

        #expect(reported?.1 == true)
        #expect(viewModel.pointsEarned == 10)
    }

    @Test func wrongQuizAnswerReportsFailureAndScoresNothing() {
        var reported: (Mission, Bool)?
        let viewModel = makeViewModel([makeQuiz()]) { reported = ($0, $1) }

        viewModel.recordCurrentQuizAnswer(wasCorrect: false)

        #expect(reported?.1 == false)
        #expect(viewModel.pointsEarned == 0)
        #expect(viewModel.result(forMissionID: "quiz.emergency_number") == .failed)
    }

    @Test func skippingAdvancesWithoutScoringOrReporting() {
        var reportCount = 0
        let viewModel = makeViewModel([makeTask(), makeQuiz()]) { _, _ in reportCount += 1 }

        viewModel.skipCurrent()

        #expect(reportCount == 0)
        #expect(viewModel.pointsEarned == 0)
        #expect(viewModel.currentMission?.id == "quiz.emergency_number")
        #expect(viewModel.result(forMissionID: "task.a") == .skipped)
    }

    @Test func completingTaskDoesNotAutoAdvance() {
        // The step view shows feedback before the user taps Next.
        let viewModel = makeViewModel([makeTask(), makeQuiz()])
        viewModel.completeCurrentTask()

        #expect(viewModel.currentMission?.id == "task.a")
        viewModel.advance()
        #expect(viewModel.currentMission?.id == "quiz.emergency_number")
    }

    @Test func quizActionIsIgnoredOnATaskStep() {
        var reportCount = 0
        let viewModel = makeViewModel([makeTask()]) { _, _ in reportCount += 1 }

        viewModel.recordCurrentQuizAnswer(wasCorrect: true)

        #expect(reportCount == 0)
        #expect(viewModel.pointsEarned == 0)
    }

    @Test func taskActionIsIgnoredOnAQuizStep() {
        var reportCount = 0
        let viewModel = makeViewModel([makeQuiz()]) { _, _ in reportCount += 1 }

        viewModel.completeCurrentTask()

        #expect(reportCount == 0)
        #expect(viewModel.pointsEarned == 0)
    }

    @Test func mixedDrillAccumulatesPointsAcrossKinds() {
        let viewModel = makeViewModel([makeTask(id: "task.a"), makeQuiz(), makeTask(id: "task.b")])

        viewModel.completeCurrentTask()
        viewModel.advance()
        viewModel.recordCurrentQuizAnswer(wasCorrect: true)
        viewModel.advance()
        viewModel.completeCurrentTask()
        viewModel.advance()

        #expect(viewModel.isFinished)
        #expect(viewModel.pointsEarned == 70)
        #expect(viewModel.session.completedCount == 3)
    }

    @Test func currentQuestionResolvesForQuizStepsOnly() {
        let viewModel = makeViewModel([makeQuiz(), makeTask()])

        #expect(viewModel.currentQuestion?.id == "quiz.emergency_number")
        viewModel.advance()
        #expect(viewModel.currentQuestion == nil)
    }

    @Test func progressFractionAdvancesWithSteps() {
        let viewModel = makeViewModel([makeTask(id: "a"), makeTask(id: "b")])

        #expect(viewModel.progressFraction == 0)
        viewModel.advance()
        #expect(abs(viewModel.progressFraction - 0.5) < 0.0001)
        viewModel.advance()
        #expect(abs(viewModel.progressFraction - 1.0) < 0.0001)
    }

    @Test func emptyDrillIsImmediatelyFinished() {
        let viewModel = makeViewModel([])

        #expect(viewModel.isFinished)
        #expect(viewModel.currentMission == nil)
        #expect(viewModel.progressFraction == 0)
    }
}
