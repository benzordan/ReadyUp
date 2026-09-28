//
//  MissionRowView.swift
//  ReadyUp
//

import SwiftUI

struct MissionRowView: View {
    let mission: Mission
    let freshness: MissionFreshness
    let onCompleteTask: () -> Void
    let onStartQuiz: () -> Void

    private var actionTitle: String {
        switch (mission.kind, freshness.state) {
        case (.task, .neverCompleted): "Mark Done"
        case (.task, _): "Refresh"
        case (.quiz, .neverCompleted): "Take Quiz"
        case (.quiz, _): "Retake"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: mission.kind == .quiz ? "questionmark.circle.fill" : "hammer.fill")
                .foregroundStyle(.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.headline)
                Text(mission.missionDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text("\(mission.pointValue) pts")
                        .font(.caption.bold())
                        .foregroundStyle(.tint)
                    MissionFreshnessBadgeView(freshness: freshness)
                    if freshness.state == .fading, let days = freshness.daysUntilExpiry {
                        Text("\(days)d left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            if freshness.state == .fresh {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Completed and current")
            } else if mission.kind == .task {
                Button(actionTitle, action: onCompleteTask)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityIdentifier("complete.\(mission.id)")
            } else {
                Button(actionTitle, action: onStartQuiz)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("quiz.\(mission.id).start")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let never = MissionFreshness(
        state: .neverCompleted, fraction: 0, contributedPoints: 0, daysUntilExpiry: nil
    )
    let fresh = MissionFreshness(
        state: .fresh, fraction: 1, contributedPoints: 10, daysUntilExpiry: 164
    )
    let expired = MissionFreshness(
        state: .expired, fraction: 0, contributedPoints: 0, daysUntilExpiry: nil
    )

    return VStack {
        MissionRowView(
            mission: Mission(
                id: "task.ready_bag",
                title: "Assemble your Ready Bag",
                missionDescription: "Pack a torchlight, spare batteries and a first aid kit.",
                kind: .task,
                pointValue: 30
            ),
            freshness: never,
            onCompleteTask: {},
            onStartQuiz: {}
        )
        MissionRowView(
            mission: Mission(
                id: "quiz.emergency_number",
                title: "Know your emergency numbers",
                missionDescription: "A quick check on which number to call.",
                kind: .quiz,
                pointValue: 10,
                completionCount: 1,
                completedAt: .now
            ),
            freshness: fresh,
            onCompleteTask: {},
            onStartQuiz: {}
        )
        MissionRowView(
            mission: Mission(
                id: "task.food_stockpile",
                title: "Build a two-week food stockpile",
                missionDescription: "Adapt, Buy, Consume and rotate your stock.",
                kind: .task,
                pointValue: 30,
                completionCount: 1,
                completedAt: .now
            ),
            freshness: expired,
            onCompleteTask: {},
            onStartQuiz: {}
        )
    }
    .padding()
}
