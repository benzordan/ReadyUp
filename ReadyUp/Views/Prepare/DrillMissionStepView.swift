//
//  DrillMissionStepView.swift
//  ReadyUp
//

import SwiftUI

struct DrillMissionStepView: View {
    let mission: Mission
    let freshness: MissionFreshness
    let quizViewModel: QuizViewModel?
    let onCompleteTask: () -> Void
    let onSkip: () -> Void
    let onAdvance: () -> Void
    let isResolved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Label(mission.domain.displayName, systemImage: mission.domain.iconSystemName)
                    .font(.caption.bold())
                    .foregroundStyle(.tint)
                MissionFreshnessBadgeView(freshness: freshness)
            }

            if let quizViewModel {
                QuizContentView(viewModel: quizViewModel, doneTitle: "Next", onDone: onAdvance)
            } else {
                taskContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mission.title)
                .font(.title3.bold())
            Text(mission.missionDescription)
                .font(.body)
                .foregroundStyle(.secondary)

            Text("\(mission.pointValue) pts")
                .font(.caption.bold())
                .foregroundStyle(.tint)

            Spacer()

            if isResolved {
                Label("Marked done", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                Button("Next", action: onAdvance)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            } else {
                Button("Mark Done", action: onCompleteTask)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("drill.complete")
                Button("Skip", action: onSkip)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("drill.skip")
            }
        }
    }
}
