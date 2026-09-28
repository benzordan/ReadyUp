//
//  AllMissionsView.swift
//  ReadyUp
//

import SwiftUI

// Flow 2, deliberately subtle: the full list is still reachable for a user who
// wants to pick something specific, but it is no longer the landing screen.
struct AllMissionsView: View {
    let viewModel: PrepareViewModel
    let onStartQuiz: (Mission) -> Void

    @State private var searchText = ""

    private var filteredMissions: [Mission] {
        guard !searchText.isEmpty else { return viewModel.missions }
        return viewModel.missions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.missionDescription.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if filteredMissions.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 40)
                } else {
                    ForEach(filteredMissions) { mission in
                        MissionRowView(
                            mission: mission,
                            freshness: viewModel.freshness(of: mission),
                            onCompleteTask: { viewModel.completeTaskMission(mission) },
                            onStartQuiz: { onStartQuiz(mission) }
                        )
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Search missions")
        .navigationTitle("Missions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
