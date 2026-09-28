//
//  HomeView.swift
//  ReadyUp
//

import SwiftUI
import SwiftData

// The dashboard that ties alerting and gamification together.
//
// Card order is deliberate: the hazard comes first because life-safety outranks
// gamification, then the preparedness score, then the drill that improves it.
struct HomeView: View {
    @Environment(AlertsViewModel.self) private var hazard
    @Environment(PrepareViewModel.self) private var prepare

    @State private var drillMissions: [Mission]?

    #if DEBUG
    @State private var isShowingDebugPanel = false
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HomeHazardCardView(viewModel: hazard)

                    ScoreHeaderView(
                        progress: prepare.scoreProgress,
                        refreshNeededCount: prepare.missionsNeedingRefreshCount,
                        peakPoints: prepare.peakPoints
                    )
                    .accessibilityIdentifier("home.preparedness")

                    DrillCTAView(
                        refreshNeededCount: prepare.missionsNeedingRefreshCount,
                        startIdentifier: "home.drill.start"
                    ) {
                        drillMissions = prepare.makeDrill()
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .refreshable { await hazard.load() }
            // Same drill flow as the Prepare tab, and deliberately the same
            // write path: both covers report results to the one shared
            // PrepareViewModel, so neither screen can drift from the other.
            .fullScreenCover(item: Binding(
                get: { drillMissions.map(DrillPayload.init) },
                set: { if $0 == nil { drillMissions = nil } }
            )) { payload in
                DrillView(
                    missions: payload.missions,
                    soundService: prepare.soundService,
                    freshnessProvider: { prepare.freshness(of: $0) },
                    onMissionResolved: prepare.resolveDrillMission
                )
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingDebugPanel = true
                    } label: {
                        Image(systemName: "ladybug.fill")
                    }
                    .accessibilityIdentifier("debug.panel")
                }
            }
            .sheet(isPresented: $isShowingDebugPanel) {
                DebugHazardPanel()
                    .presentationDetents([.medium, .large])
            }
            #endif
        }
    }
}

#Preview {
    let container = PersistenceController.makeContainer(inMemory: true)
    return HomeView()
        .modelContainer(container)
        .environment(AlertsViewModel(
            locationService: FixedLocationService(),
            hazardDataService: FixedHazardDataService(result: .success(.previewLow))
        ))
        .environment(PrepareViewModel(
            modelContext: container.mainContext,
            soundService: SilentSoundService()
        ))
}
