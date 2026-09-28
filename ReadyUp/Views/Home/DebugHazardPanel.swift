//
//  DebugHazardPanel.swift
//  ReadyUp
//

#if DEBUG
import SwiftUI

// The admin control for sampling the hazard flow, standing in for the "button
// outside the prototype" the report's feature prototype used to trigger the
// simulated storm.
//
// Debug builds only, at both this file and its toolbar entry point, so it
// cannot reach a release build. It drives the same escalation path the real
// classifier would, rather than a test-only backdoor.
struct DebugHazardPanel: View {
    @Environment(AlertsViewModel.self) private var hazard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Hazard flow") {
                    Button("Trigger escalation") {
                        // Dismiss first so the ramp is actually watchable.
                        dismiss()
                        Task { await hazard.startEscalation() }
                    }
                    .accessibilityIdentifier("debug.trigger")

                    Button("Jump to Moderate") {
                        dismiss()
                        Task { await hazard.jumpEscalation(to: .moderate) }
                    }
                    .accessibilityIdentifier("debug.jumpModerate")

                    Button("Jump to High") {
                        dismiss()
                        Task { await hazard.jumpEscalation(to: .high) }
                    }
                    .accessibilityIdentifier("debug.jumpHigh")

                    Button("Reset to resting", role: .destructive) {
                        hazard.stopEscalation()
                        hazard.acknowledgeTakeover()
                        dismiss()
                        Task { await hazard.load() }
                    }
                    .accessibilityIdentifier("debug.reset")
                }

                Section {
                    LabeledContent("Delivery", value: hazard.deliveryMode.displayName)
                        .accessibilityIdentifier("debug.deliveryMode")
                    Button("Request notification permission") {
                        Task { await hazard.requestNotificationAuthorization() }
                    }
                    // Scheduled with the system, not a Task, so it still fires
                    // once the phone is locked and the app suspended.
                    Button("Send test alert in 10 seconds") {
                        dismiss()
                        Task { await hazard.scheduleTestAlert(after: 10) }
                    }
                    .accessibilityIdentifier("debug.scheduleAlert")
                } header: {
                    Text("Critical Alerts")
                } footer: {
                    Text("Tap Send, then lock the phone and switch it to silent. A Critical Alert still sounds at full volume; a standard notification arrives without sound.")
                }

                Section("Audio") {
                    Button("Play warning audio") {
                        Task { await hazard.playWarningAudio() }
                    }
                }
            }
            .navigationTitle("Hazard test panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    DebugHazardPanel()
        .environment(AlertsViewModel(
            locationService: FixedLocationService(),
            hazardDataService: FixedHazardDataService()
        ))
}
#endif
