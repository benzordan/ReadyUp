//
//  HazardDomainDetailView.swift
//  ReadyUp
//

import SwiftUI

struct HazardDomainDetailView: View {
    let domain: HazardDomain
    let viewModel: PrepareViewModel
    let onStartQuiz: (Mission) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(domain.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(viewModel.missions(in: domain)) { mission in
                    MissionRowView(
                        mission: mission,
                        freshness: viewModel.freshness(of: mission),
                        onCompleteTask: { viewModel.completeTaskMission(mission) },
                        onStartQuiz: { onStartQuiz(mission) }
                    )
                }

                // The Resource Hub carries the full procedure behind each of
                // these missions, so the domain screen links straight to it.
                if let category = domain.resourceCategory {
                    NavigationLink(value: category) {
                        Label("Read the guides", systemImage: "book.fill")
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle(domain.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
