//
//  QuizContentView.swift
//  ReadyUp
//

import SwiftUI

// The quiz body without any presentation chrome, so it can be shown either as
// a sheet (QuizView) or embedded inline as one step of a drill. Every visible
// string is unchanged from the original sheet.
struct QuizContentView: View {
    @Bindable var viewModel: QuizViewModel
    let doneTitle: String
    let onDone: () -> Void

    init(
        viewModel: QuizViewModel,
        doneTitle: String = "Done",
        onDone: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.doneTitle = doneTitle
        self.onDone = onDone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(viewModel.question.prompt)
                .font(.title3.bold())

            VStack(spacing: 10) {
                ForEach(Array(viewModel.question.choices.enumerated()), id: \.offset) { index, choice in
                    Button {
                        viewModel.selectAnswer(index)
                    } label: {
                        HStack {
                            Text(choice)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if viewModel.selectedAnswerIndex == index {
                                Image(systemName: "circle.inset.filled")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(tint(for: index))
                    // Locks the choices without .disabled(), which would grey
                    // them out and hide the green/red answer feedback.
                    .allowsHitTesting(!viewModel.isSubmitted)
                }
            }

            Spacer()

            if viewModel.isSubmitted {
                Text(feedbackMessage)
                    .font(.subheadline.bold())
                    .foregroundStyle(viewModel.isCorrect == true ? .green : .red)
                Button(doneTitle, action: onDone)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            } else {
                Button("Submit") { viewModel.submit() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.selectedAnswerIndex == nil)
            }
        }
    }

    private var feedbackMessage: String {
        viewModel.isCorrect == true
            ? "Correct!"
            : "Not quite. The correct answer is highlighted in green."
    }

    // ========================================
    // private func tint(for index: Int) -> Color
    // Chooses the colour of an answer button: neutral before submitting, then green for the correct answer and red for a wrong selection.
    // Returns: The Color to tint the button at that index.
    // ========================================
    private func tint(for index: Int) -> Color {
        guard viewModel.isSubmitted else { return .accentColor }
        if index == viewModel.question.correctAnswerIndex { return .green }
        if index == viewModel.selectedAnswerIndex { return .red }
        return .secondary
    }
}
