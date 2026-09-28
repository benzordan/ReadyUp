//
//  RainfallCardView.swift
//  ReadyUp
//

import SwiftUI

struct RainfallCardView: View {
    let reading: HazardReading
    let rainfallText: String

    private var distanceText: String {
        let kilometres = reading.stationDistanceMetres / 1000
        return kilometres < 1
            ? "\(Int(reading.stationDistanceMetres)) m away"
            : String(format: "%.1f km away", kilometres)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Rainfall")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(rainfallText)
                    .font(.largeTitle.bold().monospacedDigit())
                Text("mm")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text("per 5 min · \(reading.stationName), \(distanceText)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Absolute time, not relative: a relative style would be rendered
            // once and then silently go stale as the screen stays open.
            Text("Reading at \(reading.observedAt, format: .dateTime.hour().minute())")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rainfallText) millimetres of rain in the last 5 minutes at \(reading.stationName)")
    }
}

#Preview {
    VStack {
        RainfallCardView(reading: .previewLow, rainfallText: "0.0")
        RainfallCardView(reading: .preview(millimetres: 6), rainfallText: "6.0")
    }
    .padding()
}
