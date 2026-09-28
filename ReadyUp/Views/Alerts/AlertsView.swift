//
//  AlertsView.swift
//  ReadyUp
//

import SwiftUI

// The Alerts tab's resting state: which zone the user is in, the current risk
// classification, and the live rainfall behind it. Escalation, the takeover and
// the audio warning are driven by AlertsViewModel and presented in RootTabView.
struct AlertsView: View {
    @Environment(AlertsViewModel.self) private var viewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                content(for: viewModel)
                    .padding()
            }
            .navigationTitle("Alerts")
            .refreshable { await viewModel.load() }
        }
    }

    @ViewBuilder
    private func content(for viewModel: AlertsViewModel) -> some View {
        if let reading = viewModel.reading, let tier = viewModel.tier {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isShowingStaleReading {
                    Label("Couldn't refresh. Showing the last reading.", systemImage: "wifi.slash")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Label(reading.zoneName, systemImage: "location.fill")
                        .font(.title2.bold())
                    Text("Singapore")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("alerts.zone")

                AlertTierPillView(tier: tier, kind: viewModel.leadingKind)
                    .accessibilityIdentifier("alerts.tier")

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.leadingKind.situation(at: tier))
                        .font(.headline)
                    Text(viewModel.leadingKind.protectiveAction(at: tier))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                RainfallCardView(reading: reading, rainfallText: viewModel.rainfallText ?? "—")
                    .accessibilityIdentifier("alerts.rainfall")

                secondaryHazards(reading: reading)

                if !reading.forecast.isEmpty {
                    Label("Next 2 hours: \(reading.forecast)", systemImage: "cloud.sun.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Checking your area…")
                    .frame(maxWidth: .infinity, minHeight: 240)
            case .loaded:
                unavailable(
                    "No reading available",
                    icon: "questionmark.circle",
                    message: "NEA has no rainfall data for your area right now.",
                    viewModel: viewModel
                )
            case .failed(let failure):
                failureView(failure, viewModel: viewModel)
            }
        }
    }

    // The secondary hazards, each with its live value and tier. A hazard whose
    // feed gave no usable signal is hidden rather than shown as a made-up Low.
    @ViewBuilder
    private func secondaryHazards(reading: HazardReading) -> some View {
        if let assessment = viewModel.assessment, assessment.haze != nil || assessment.heat != nil {
            VStack(alignment: .leading, spacing: 10) {
                Text("Haze & heat")
                    .font(.headline)
                if let haze = assessment.haze, let psi = reading.psi {
                    secondaryHazardRow(name: "Haze", value: "PSI \(psi)", tier: haze)
                }
                if let heat = assessment.heat, let celsius = reading.airTemperatureCelsius {
                    secondaryHazardRow(name: "Heat", value: String(format: "%.1f°C", celsius), tier: heat)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("alerts.secondaryHazards")
        }
    }

    private func secondaryHazardRow(name: String, value: String, tier: AlertTier) -> some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(tier.displayName)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(tier.color.opacity(0.15), in: Capsule())
                .foregroundStyle(tier.color)
        }
    }

    @ViewBuilder
    private func failureView(_ failure: AlertsFailure, viewModel: AlertsViewModel) -> some View {
        switch failure {
        case .locationDenied:
            ContentUnavailableView {
                Label("Location access needed", systemImage: "location.slash.fill")
            } description: {
                Text("ReadyUp needs your location to show the hazard risk for your area.")
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

        case .outsideCoverage:
            unavailable(
                "Outside coverage area",
                icon: "globe.asia.australia",
                message: "ReadyUp uses Singapore's NEA hazard data, so it only covers Singapore.",
                viewModel: viewModel
            )

        case .locationUnavailable:
            unavailable(
                "Couldn't find your location",
                icon: "location.slash",
                message: "Check that Location Services is on, then try again.",
                viewModel: viewModel
            )

        case .networkUnavailable:
            unavailable(
                "Couldn't get the latest reading",
                icon: "wifi.slash",
                message: "Check your connection and try again.",
                viewModel: viewModel
            )
        }
    }

    private func unavailable(
        _ title: String,
        icon: String,
        message: String,
        viewModel: AlertsViewModel
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("alerts.retry")
        }
    }
}

#Preview {
    AlertsView()
        .environment(AlertsViewModel(
            locationService: FixedLocationService(),
            hazardDataService: FixedHazardDataService(result: .success(.previewModerate))
        ))
}
