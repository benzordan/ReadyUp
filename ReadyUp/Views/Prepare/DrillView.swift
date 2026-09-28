//
//  DrillView.swift
//  ReadyUp
//

import SwiftUI

struct DrillView: View {
    @State private var viewModel: DrillViewModel
    // Rebuilt per quiz step so each question starts with clean selection state.
    @State private var quizViewModel: QuizViewModel?

    @Environment(\.dismiss) private var dismiss

    private let soundService: SoundServicing
    private let freshnessProvider: (Mission) -> MissionFreshness

    init(
        missions: [Mission],
        soundService: SoundServicing,
        freshnessProvider: @escaping (Mission) -> MissionFreshness,
        onMissionResolved: @escaping (Mission, Bool) -> Void
    ) {
        self.soundService = soundService
        self.freshnessProvider = freshnessProvider
        _viewModel = State(
            initialValue: DrillViewModel(
                missions: missions,
                soundService: soundService,
                onMissionResolved: onMissionResolved
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isFinished {
                    DrillSummaryView(
                        missions: viewModel.missions,
                        results: viewModel.session.results,
                        pointsEarned: viewModel.pointsEarned,
                        onDone: { dismiss() }
                    )
                } else if let mission = viewModel.currentMission {
                    VStack(alignment: .leading, spacing: 16) {
                        ProgressView(value: viewModel.progressFraction)
                            .tint(.accentColor)

                        DrillMissionStepView(
                            mission: mission,
                            freshness: freshnessProvider(mission),
                            quizViewModel: quizViewModel,
                            onCompleteTask: { viewModel.completeCurrentTask() },
                            onSkip: { advance() },
                            onAdvance: { advance() },
                            isResolved: viewModel.result(forMissionID: mission.id) != nil
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "Nothing to drill",
                        systemImage: "checkmark.circle",
                        description: Text("Every mission is current. Come back when something needs refreshing.")
                    )
                }
            }
            .padding()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { prepareQuizIfNeeded() }
        }
    }

    private var navigationTitle: String {
        viewModel.isFinished ? "Summary" : "Step \(viewModel.stepNumber) of \(viewModel.totalSteps)"
    }

    // ========================================
    // private func advance()
    // Moves the drill to the next step and rebuilds the quiz state for it, so answers never carry over between questions.
    // Returns: Nothing.
    // ========================================
    private func advance() {
        if viewModel.result(forMissionID: viewModel.currentMission?.id ?? "") == nil,
           viewModel.currentMission?.kind == .task {
            viewModel.skipCurrent()
        } else {
            viewModel.advance()
        }
        prepareQuizIfNeeded()
    }

    // ========================================
    // private func prepareQuizIfNeeded()
    // Builds a fresh QuizViewModel when the current step is a quiz, and clears it otherwise so a task step never renders stale quiz UI.
    // Returns: Nothing.
    // ========================================
    private func prepareQuizIfNeeded() {
        guard let mission = viewModel.currentMission,
              let question = viewModel.currentQuestion else {
            quizViewModel = nil
            return
        }

        quizViewModel = QuizViewModel(
            mission: mission,
            question: question,
            soundService: soundService,
            onAnswered: { _, wasCorrect in
                viewModel.recordCurrentQuizAnswer(wasCorrect: wasCorrect)
            }
        )
    }
}
