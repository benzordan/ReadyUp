//
//  ScoreHeaderView.swift
//  ReadyUp
//

import SwiftUI

struct ScoreHeaderView: View {
    let progress: ScoreProgress
    var refreshNeededCount: Int = 0
    var peakPoints: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(progress.tier.displayName)
                    .font(.title2.bold())
                Spacer()
                Text("\(progress.points) pts")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress.fractionToNextTier)
                .tint(.accentColor)

            if let nextTier = progress.nextTier {
                Text("\(progress.pointsToNextTier) pts to \(nextTier.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Top tier reached")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Naming the cause matters: a score that falls without explanation
            // reads as a bug rather than a prompt.
            if refreshNeededCount > 0 {
                Label(
                    "\(refreshNeededCount) \(refreshNeededCount == 1 ? "mission needs" : "missions need") refreshing",
                    systemImage: "clock.arrow.circlepath"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }

            if peakPoints > progress.points {
                Text("Best: \(peakPoints) pts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack {
        ScoreHeaderView(progress: PreparednessScoring.progress(forPoints: 0))
        ScoreHeaderView(
            progress: PreparednessScoring.progress(forPoints: 160),
            refreshNeededCount: 3,
            peakPoints: 240
        )
        ScoreHeaderView(progress: PreparednessScoring.progress(forPoints: 660))
    }
    .padding()
}
