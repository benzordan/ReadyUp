//
//  AlertTierPillView.swift
//  ReadyUp
//

import SwiftUI

struct AlertTierPillView: View {
    let tier: AlertTier
    // The hazard whose situation line the pill shows — the leading one.
    let kind: HazardKind

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tier.iconSystemName)
            Text("\(tier.displayName) — \(kind.situation(at: tier))")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(tier.color.opacity(0.15), in: Capsule())
        .foregroundStyle(tier.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Risk level \(tier.displayName). \(kind.situation(at: tier))")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(AlertTier.allCases) { AlertTierPillView(tier: $0, kind: .flashFlood) }
    }
    .padding()
}
