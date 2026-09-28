//
//  ReadyUpApp.swift
//  ReadyUp
//
//  Created by Ben Zordan on 29/7/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ReadyUpApp: App {
    // The composition root. Both view models are owned here and shared through
    // the environment, so the Home dashboard and the Prepare and Alerts tabs
    // read exactly one hazard picture and one score. A drill completed on Home
    // is therefore already reflected on Prepare, with no refresh plumbing.
    private let container: ModelContainer

    @State private var hazard: AlertsViewModel
    @State private var prepare: PrepareViewModel

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("-uitesting")

        // UI tests run against a fresh in-memory store so each test starts from
        // the seeded state rather than inheriting the previous test's progress.
        let container = isUITesting
            ? PersistenceController.makeContainer(inMemory: true)
            : PersistenceController.sharedModelContainer
        let clock = AppClock.fromLaunchArguments(arguments)

        #if DEBUG
        // Backdated completions for demonstrating and testing decay.
        if arguments.contains("-seedStaleProgress") {
            PersistenceController.applyDebugStaleProgress(container: container, asOf: clock.now())
        }
        #endif

        // Substituting the fakes under UI testing is not optional: otherwise the
        // test run hits the live NEA API and a real location permission prompt.
        let locationService: LocationServicing = isUITesting
            ? FixedLocationService()
            : CoreLocationService()
        let hazardDataService: HazardDataServicing = isUITesting
            ? FixedHazardDataService.fromLaunchArguments(arguments)
            : NEAHazardDataService()
        // Silencing these under UI testing is not optional: otherwise the test
        // run raises a real notification prompt and plays a real alarm tone.
        let alertAudio: AlertAudioServicing = isUITesting
            ? SilentAlertAudioService()
            : SystemAlertAudioService()
        let notifications = isUITesting
            ? SilentNotificationService() as NotificationServicing
            : SystemNotificationService()

        let hazard = AlertsViewModel(
            locationService: locationService,
            hazardDataService: hazardDataService,
            alertAudio: alertAudio,
            notificationService: notifications
        )

        // Assigned in init rather than a .task: a notification tapped from a
        // cold launch is delivered before the first view appears.
        if let system = notifications as? SystemNotificationService {
            UNUserNotificationCenter.current().delegate = system
            system.onAlertTapped = { [weak hazard] in hazard?.showTakeoverFromNotification() }
        }

        self.container = container
        _hazard = State(initialValue: hazard)
        _prepare = State(
            initialValue: PrepareViewModel(
                modelContext: container.mainContext,
                soundService: isUITesting ? SilentSoundService() : SystemSoundService(),
                clock: clock.now
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
        .environment(hazard)
        .environment(prepare)
    }
}
