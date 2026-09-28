//
//  HomeHazardCardView.swift
//  ReadyUp
//

import SwiftUI

// The dashboard's hazard summary.
//
// Every state renders inside the same card chrome so the preparedness and drill
// cards below never shift or disappear while hazard data is loading or has
// failed. Deliberately terser than the Alerts tab: Home is a glance, Alerts is
// where the full explanation lives.
struct HomeHazardCardView: View {
    let viewModel: AlertsViewModel

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let reading = viewModel.reading, let tier = viewModel.tier {
                loaded(reading: reading, tier: tier)
            } else {
                switch viewModel.state {
                case .idle, .loading:
                    checking
                case .loaded:
                    message("No reading available for your area.", icon: "questionmark.circle")
                case .failed(let failure):
                    failed(failure)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("home.hazard")
    }

    @ViewBuilder
    private func loaded(reading: HazardReading, tier: AlertTier) -> some View {
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

        AlertTierPillView(tier: tier, kind: viewModel.leadingKind)
            .accessibilityIdentifier("home.hazard.tier")

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(viewModel.rainfallText ?? "—")
                .font(.largeTitle.bold().monospacedDigit())
            Text("mm")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("per 5 min")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var checking: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Checking your area…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
    }

    @ViewBuilder
    private func failed(_ failure: AlertsFailure) -> some View {
        switch failure {
        case .locationDenied:
            message("Location access needed to show your local risk.", icon: "location.slash.fill")
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

        case .outsideCoverage:
            message("Outside coverage. ReadyUp covers Singapore only.", icon: "globe.asia.australia")

        case .locationUnavailable:
            message("Couldn't find your location.", icon: "location.slash")
            retryButton

        case .networkUnavailable:
            message("Couldn't get the latest reading.", icon: "wifi.slash")
            retryButton
        }
    }

    private func message(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
    }

    private var retryButton: some View {
        Button("Try Again") {
            Task { await viewModel.load() }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityIdentifier("home.hazard.retry")
    }
}

#Preview {
    VStack(spacing: 16) {
        HomeHazardCardView(viewModel: AlertsViewModel(
            locationService: FixedLocationService(),
            hazardDataService: FixedHazardDataService(result: .success(.previewModerate))
        ))
        HomeHazardCardView(viewModel: AlertsViewModel(
            locationService: FixedLocationService(result: .failure(.authorizationDenied)),
            hazardDataService: FixedHazardDataService()
        ))
    }
    .padding()
}
