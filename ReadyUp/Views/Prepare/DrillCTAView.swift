//
//  DrillCTAView.swift
//  ReadyUp
//

import SwiftUI

// Flow 1's entry point, and the most prominent thing on the Prepare tab: one
// tap to a short, decided-for-you set of missions, rather than asking a
// rarely-visiting user to choose from a long list.
struct DrillCTAView: View {
    let refreshNeededCount: Int
    // Home and Prepare both render this card. Without distinct identifiers the
    // start button exists in two tab hierarchies and XCUITest lookups become
    // order-dependent.
    var startIdentifier: String = "drill.start"
    let onStart: () -> Void

    private var subtitle: String {
        if refreshNeededCount > 0 {
            return "\(refreshNeededCount) \(refreshNeededCount == 1 ? "mission has" : "missions have") gone stale. A drill puts them first."
        }
        return "Three missions, about two minutes."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Today's drill", systemImage: "bolt.fill")
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Start a drill", action: onStart)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(startIdentifier)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack {
        DrillCTAView(refreshNeededCount: 0, onStart: {})
        DrillCTAView(refreshNeededCount: 2, onStart: {})
    }
    .padding()
}
