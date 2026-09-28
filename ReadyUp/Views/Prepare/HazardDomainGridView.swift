//
//  HazardDomainGridView.swift
//  ReadyUp
//

import SwiftUI

struct HazardDomainGridView: View {
    let summaries: [HazardDomainSummary]

    // Fixed two columns rather than adaptive, matching the Resource Hub grid,
    // so the layout stays predictable for a user who opens the app rarely.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(summaries) { summary in
                NavigationLink(value: summary.domain) {
                    HazardDomainTileView(summary: summary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            HazardDomainGridView(
                summaries: HazardDomainSummarizer.summaries(
                    missions: MissionSeedData.starterMissions,
                    asOf: .now
                )
            )
            .padding()
        }
    }
}
