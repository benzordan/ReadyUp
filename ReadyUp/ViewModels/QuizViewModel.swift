//
//  QuizViewModel.swift
//  ReadyUp
//

import Foundation
import Observation

// Owns only the short-lived state of one quiz sheet, so it resets cleanly each
// time a quiz is opened and can be tested without touching persistence.
@MainActor
@Observable
final class QuizViewModel {

    let mission: Mission
    let question: QuizQuestion

    private let soundService: SoundServicing
    private let onAnswered: (Mission, Bool) -> Void

    private(set) var selectedAnswerIndex: Int?
    private(set) var isSubmitted = false

    var isCorrect: Bool? {
        guard isSubmitted, let selectedAnswerIndex else { return nil }
        return selectedAnswerIndex == question.correctAnswerIndex
    }

    init(
        mission: Mission,
        question: QuizQuestion,
        soundService: SoundServicing,
        onAnswered: @escaping (Mission, Bool) -> Void
    ) {
        self.mission = mission
        self.question = question
        self.soundService = soundService
        self.onAnswered = onAnswered
    }

    // ========================================
    // func selectAnswer(_ index: Int)
    // Records the user's choice. Ignored once the answer has been submitted so the selection cannot be changed after scoring.
    // Returns: Nothing.
    // ========================================
    func selectAnswer(_ index: Int) {
        guard !isSubmitted else { return }
        selectedAnswerIndex = index
    }

    // ========================================
    // func submit()
    // Scores the selected answer, plays the reward sound only when it is correct, and reports the result back so the mission can be completed.
    // Returns: Nothing.
    // ========================================
    func submit() {
        guard let selectedAnswerIndex, !isSubmitted else { return }
        isSubmitted = true

        let correct = selectedAnswerIndex == question.correctAnswerIndex
        if correct {
            soundService.playCorrectAnswer()
        }
        onAnswered(mission, correct)
    }
}
