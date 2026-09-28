//
//  BadgeUnlockToast.swift
//  ReadyUp
//

import SwiftUI

struct BadgeUnlockToast: View {
    let badge: BadgeDefinition
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: badge.iconSystemName)
                .font(.title2)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Badge unlocked")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(badge.title)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8, y: 4)
        .padding(.horizontal)
        .onTapGesture(perform: onDismiss)
        .task(id: badge.id) {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }
}

#Preview {
    BadgeUnlockToast(badge: BadgeLibrary.all[0], onDismiss: {})
}
