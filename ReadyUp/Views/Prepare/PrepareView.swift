//
//  PrepareView.swift
//  ReadyUp
//

import SwiftUI
import SwiftData

// Three ways in, deliberately unequal in prominence:
//   Flow 1, the drill, is the headline call to action.
//   Flow 3, the hazard grid, is the browse-by-area route.
//   Flow 2, the full mission list, sits behind a quiet link at the bottom.
struct PrepareView: View {
    @Environment(PrepareViewModel.self) private var viewModel

    @State private var activeQuizMission: Mission?
    @State private var drillMissions: [Mission]?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScoreHeaderView(
                        progress: viewModel.scoreProgress,
                        refreshNeededCount: viewModel.missionsNeedingRefreshCount,
                        peakPoints: viewModel.peakPoints
                    )

                    DrillCTAView(refreshNeededCount: viewModel.missionsNeedingRefreshCount) {
                        drillMissions = viewModel.makeDrill()
                    }

                    Text("Hazard areas")
                        .font(.headline)
                        .padding(.top, 4)

                    HazardDomainGridView(summaries: viewModel.domainSummaries)

                    BadgeShelfView(earnedBadgeIDs: viewModel.earnedBadgeIDs)

                    NavigationLink(value: PrepareRoute.allMissions) {
                        Label("Browse all missions", systemImage: "list.bullet")
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Prepare")
            .navigationDestination(for: PrepareRoute.self) { route in
                if route == .allMissions {
                    AllMissionsView(viewModel: viewModel) { activeQuizMission = $0 }
                }
            }
            .navigationDestination(for: HazardDomain.self) { domain in
                HazardDomainDetailView(domain: domain, viewModel: viewModel) {
                    activeQuizMission = $0
                }
            }
            // The hazard screens link straight into the Resource Hub's fuller
            // guidance rather than duplicating it here.
            .navigationDestination(for: ResourceCategory.self) { category in
                ResourceCategoryDetailView(category: category)
            }
            .navigationDestination(for: ResourceArticle.self) { article in
                ResourceArticleDetailView(article: article)
            }
            .overlay(alignment: .top) {
                if let badge = viewModel.newlyUnlockedBadges.first {
                    BadgeUnlockToast(badge: badge) {
                        withAnimation { viewModel.dismissNewlyUnlockedBadges() }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(item: $activeQuizMission) { mission in
                if let question = QuizLibrary.question(forMissionID: mission.id) {
                    QuizView(
                        mission: mission,
                        question: question,
                        soundService: viewModel.soundService
                    ) { answeredMission, wasCorrect in
                        viewModel.completeQuizMission(answeredMission, wasCorrect: wasCorrect)
                    }
                }
            }
            .fullScreenCover(item: Binding(
                get: { drillMissions.map(DrillPayload.init) },
                set: { if $0 == nil { drillMissions = nil } }
            )) { payload in
                DrillView(
                    missions: payload.missions,
                    soundService: viewModel.soundService,
                    freshnessProvider: { viewModel.freshness(of: $0) },
                    onMissionResolved: viewModel.resolveDrillMission
                )
            }
        }
    }
}

enum PrepareRoute: Hashable {
    case allMissions
}

#Preview {
    let container = PersistenceController.makeContainer(inMemory: true)
    return PrepareView()
        .modelContainer(container)
        .environment(PrepareViewModel(
            modelContext: container.mainContext,
            soundService: SilentSoundService()
        ))
}
