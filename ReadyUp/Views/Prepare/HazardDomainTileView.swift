//
//  HazardDomainTileView.swift
//  ReadyUp
//

import SwiftUI

struct HazardDomainTileView: View {
    let summary: HazardDomainSummary

    private var statusTint: Color {
        summary.needsRefreshMissions > 0 ? .orange : .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: summary.domain.iconSystemName)
                .font(.title)
                .foregroundStyle(.tint)

            Text(summary.domain.shortName)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(summary.statusText)
                .font(.caption)
                .foregroundStyle(statusTint)
                .lineLimit(2)

            ProgressView(value: summary.fractionOfMax)
                .tint(.accentColor)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.domain.displayName). \(summary.statusText).")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    let missions = MissionSeedData.starterMissions
    let summaries = HazardDomainSummarizer.summaries(missions: missions, asOf: .now)

    return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
        ForEach(summaries) { HazardDomainTileView(summary: $0) }
    }
    .padding()
}
