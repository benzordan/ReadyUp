//
//  DrillSummaryView.swift
//  ReadyUp
//

import SwiftUI

struct DrillSummaryView: View {
    let missions: [Mission]
    let results: [String: DrillStepResult]
    let pointsEarned: Int
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Drill complete")
                    .font(.title2.bold())
                Text("+\(pointsEarned) pts earned")
                    .font(.headline)
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 10) {
                ForEach(missions) { mission in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon(for: results[mission.id]))
                            .foregroundStyle(color(for: results[mission.id]))
                        Text(mission.title)
                            .font(.subheadline)
                        Spacer(minLength: 8)
                        Text(label(for: results[mission.id]))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("drill.done")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ========================================
    // private func icon(for result: DrillStepResult?) -> String
    // Picks the symbol summarising one drill step's outcome.
    // Returns: An SF Symbol name for the result, defaulting to the skipped symbol.
    // ========================================
    private func icon(for result: DrillStepResult?) -> String {
        switch result {
        case .completed: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        default: "minus.circle"
        }
    }

    private func color(for result: DrillStepResult?) -> Color {
        switch result {
        case .completed: .green
        case .failed: .red
        default: .secondary
        }
    }

    private func label(for result: DrillStepResult?) -> String {
        switch result {
        case .completed(let points): "+\(points) pts"
        case .failed: "Try again later"
        default: "Skipped"
        }
    }
}

#Preview {
    let missions = Array(MissionSeedData.starterMissions.prefix(3))
    return DrillSummaryView(
        missions: missions,
        results: [
            missions[0].id: .completed(points: 30),
            missions[1].id: .failed,
            missions[2].id: .skipped
        ],
        pointsEarned: 30,
        onDone: {}
    )
    .padding()
}
