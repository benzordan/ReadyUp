//
//  AlertTakeoverView.swift
//  ReadyUp
//

import SwiftUI

// The High-tier escalation screen from the report's feature prototype: a
// full-screen warning that states the hazard and the required action, and
// cannot be missed.
//
// Every string comes from the shared HazardKind table and the colour from the
// AlertTier table, so this screen, the notification and the spoken instruction
// cannot drift apart.
struct AlertTakeoverView: View {
    let kind: HazardKind
    let zoneName: String
    let deliveryMode: AlertDeliveryMode
    let onAcknowledge: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            AlertTier.high.color.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("EMERGENCY ALERT · SINGAPORE")
                    .font(.caption.bold())
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Image(systemName: AlertTier.high.iconSystemName)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)

                Text(kind.takeoverHeadline)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .opacity(isPulsing ? 0.55 : 1)
                    .animation(
                        .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                Label(zoneName, systemImage: "location.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2), in: Capsule())

                VStack(spacing: 8) {
                    Text(kind.situation(at: .high))
                        .font(.title2.bold())
                    Text(kind.protectiveAction(at: .high))
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding(.horizontal)

                Spacer()

                Button("Acknowledge", action: onAcknowledge)
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(AlertTier.high.color)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("alert.acknowledge")

                // The honest read-out: without Critical Alerts, a warning can be
                // silenced when the phone is locked or muted, and the screen says
                // so rather than implying a guarantee it cannot keep.
                if deliveryMode != .critical {
                    Text(deliveryMode.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
        }
        .accessibilityAddTraits(.isModal)
        .onAppear {
            // A flashing full-screen red is a photosensitivity and vestibular
            // concern, so the pulse honours the system setting.
            if !reduceMotion { isPulsing = true }
        }
    }
}

#Preview {
    AlertTakeoverView(kind: .flashFlood, zoneName: "Bedok", deliveryMode: .critical, onAcknowledge: {})
}
