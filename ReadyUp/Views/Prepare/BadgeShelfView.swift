//
//  BadgeShelfView.swift
//  ReadyUp
//

import SwiftUI

struct BadgeShelfView: View {
    let earnedBadgeIDs: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Badges")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(BadgeLibrary.all) { badge in
                        let isEarned = earnedBadgeIDs.contains(badge.id)
                        VStack(spacing: 6) {
                            Image(systemName: badge.iconSystemName)
                                .font(.title)
                                .foregroundStyle(isEarned ? Color.yellow : Color.secondary.opacity(0.35))
                            Text(badge.title)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(isEarned ? .primary : .secondary)
                        }
                        .frame(width: 76)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(badge.title), \(isEarned ? "earned" : "locked"). \(badge.badgeDescription)"
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    BadgeShelfView(earnedBadgeIDs: ["first_step", "tier_prepared"])
        .padding()
}
