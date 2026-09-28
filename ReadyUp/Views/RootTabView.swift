//
//  RootTabView.swift
//  ReadyUp
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(AlertsViewModel.self) private var hazard
    @Environment(PrepareViewModel.self) private var prepare
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            PrepareView()
                .tabItem { Label("Prepare", systemImage: "checklist") }
            AlertsView()
                .tabItem { Label("Alerts", systemImage: "exclamationmark.triangle.fill") }
            ResourceHubView()
                .tabItem { Label("Resource Hub", systemImage: "books.vertical.fill") }
        }
        // The single lifecycle site for both shared view models. Keeping it here
        // rather than in each tab stops the same NEA fetch running twice, and
        // means freshness is recomputed once when the app returns to the front.
        .task { await hazard.load() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            prepare.refresh()
            Task { await hazard.load() }
        }
        // Presented once, above the tabs, so a notification tap lands on it
        // whichever tab is showing and two covers can never race.
        .fullScreenCover(isPresented: Binding(
            get: { hazard.isShowingTakeover },
            set: { if !$0 { hazard.acknowledgeTakeover() } }
        )) {
            AlertTakeoverView(
                kind: hazard.takeoverKind,
                zoneName: hazard.reading?.zoneName ?? "your area",
                deliveryMode: hazard.deliveryMode,
                onAcknowledge: { hazard.acknowledgeTakeover() }
            )
        }
    }
}

#Preview {
    let container = PersistenceController.makeContainer(inMemory: true)
    return RootTabView()
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
