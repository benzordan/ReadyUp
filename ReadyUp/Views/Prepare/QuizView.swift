//
//  QuizView.swift
//  ReadyUp
//

import SwiftUI

// Sheet presentation of a single quiz. The body itself lives in
// QuizContentView so the drill can embed the same UI without a nested
// NavigationStack.
struct QuizView: View {
    @State private var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        mission: Mission,
        question: QuizQuestion,
        soundService: SoundServicing,
        onAnswered: @escaping (Mission, Bool) -> Void
    ) {
        _viewModel = State(
            initialValue: QuizViewModel(
                mission: mission,
                question: question,
                soundService: soundService,
                onAnswered: onAnswered
            )
        )
    }

    var body: some View {
        NavigationStack {
            QuizContentView(viewModel: viewModel) { dismiss() }
                .padding()
                .navigationTitle("Quiz")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    QuizView(
        mission: Mission(
            id: "quiz.emergency_number",
            title: "Know your emergency numbers",
            missionDescription: "A quick check.",
            kind: .quiz,
            pointValue: 10
        ),
        question: QuizLibrary.questions[0],
        soundService: SilentSoundService(),
        onAnswered: { _, _ in }
    )
}
