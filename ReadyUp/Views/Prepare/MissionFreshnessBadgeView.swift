//
//  MissionFreshnessBadgeView.swift
//  ReadyUp
//

import SwiftUI

struct MissionFreshnessBadgeView: View {
    let freshness: MissionFreshness

    private var tint: Color {
        switch freshness.state {
        case .fresh: .green
        case .fading: .orange
        case .expired: .red
        case .neverCompleted: .secondary
        }
    }

    var body: some View {
        Text(freshness.state.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ForEach(MissionFreshnessState.allCases, id: \.self) { state in
            MissionFreshnessBadgeView(
                freshness: MissionFreshness(
                    state: state,
                    fraction: 1,
                    contributedPoints: 30,
                    daysUntilExpiry: nil
                )
            )
        }
    }
    .padding()
}
