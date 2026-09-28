//
//  QuizViewModelTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

@MainActor
struct QuizViewModelTests {

    private func makeQuestion() -> QuizQuestion {
        QuizQuestion(
            id: "quiz.test",
            prompt: "Which number do you call for fire and ambulance?",
            choices: ["999", "995", "911", "112"],
            correctAnswerIndex: 1
        )
    }

    private func makeMission() -> Mission {
        Mission(id: "quiz.test", title: "Test", missionDescription: "Test", kind: .quiz, pointValue: 10)
    }

    @Test func correctAnswerReportsCorrectAndPlaysSound() {
        let sound = SilentSoundService()
        var callbackResult: Bool?

        let viewModel = QuizViewModel(
            mission: makeMission(),
            question: makeQuestion(),
            soundService: sound
        ) { _, correct in callbackResult = correct }

        viewModel.selectAnswer(1)
        viewModel.submit()

        #expect(viewModel.isCorrect == true)
        #expect(callbackResult == true)
        #expect(sound.playedEvents == [.correctAnswer])
    }

    @Test func wrongAnswerReportsIncorrectAndPlaysNoSound() {
        let sound = SilentSoundService()
        var callbackResult: Bool?

        let viewModel = QuizViewModel(
            mission: makeMission(),
            question: makeQuestion(),
            soundService: sound
        ) { _, correct in callbackResult = correct }

        viewModel.selectAnswer(0)
        viewModel.submit()

        #expect(viewModel.isCorrect == false)
        #expect(callbackResult == false)
        #expect(sound.playedEvents.isEmpty)
    }

    @Test func submittingWithoutSelectingDoesNothing() {
        let sound = SilentSoundService()
        var callbackFired = false

        let viewModel = QuizViewModel(
            mission: makeMission(),
            question: makeQuestion(),
            soundService: sound
        ) { _, _ in callbackFired = true }

        viewModel.submit()

        #expect(viewModel.isSubmitted == false)
        #expect(callbackFired == false)
    }

    @Test func selectionCannotChangeAfterSubmitting() {
        let viewModel = QuizViewModel(
            mission: makeMission(),
            question: makeQuestion(),
            soundService: SilentSoundService()
        ) { _, _ in }

        viewModel.selectAnswer(1)
        viewModel.submit()
        viewModel.selectAnswer(0)

        #expect(viewModel.selectedAnswerIndex == 1)
        #expect(viewModel.isCorrect == true)
    }

    @Test func submittingTwiceOnlyReportsOnce() {
        var callbackCount = 0

        let viewModel = QuizViewModel(
            mission: makeMission(),
            question: makeQuestion(),
            soundService: SilentSoundService()
        ) { _, _ in callbackCount += 1 }

        viewModel.selectAnswer(1)
        viewModel.submit()
        viewModel.submit()

        #expect(callbackCount == 1)
    }

    @Test func everySeededQuizMissionHasMatchingQuestion() {
        for mission in MissionSeedData.quizMissions {
            #expect(QuizLibrary.question(forMissionID: mission.id) != nil)
        }
    }
}
