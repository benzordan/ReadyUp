//
//  EmergencyContactRowView.swift
//  ReadyUp
//

import SwiftUI

struct EmergencyContactRowView: View {
    let contact: EmergencyContact

    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: contact.method == .sms ? "message.fill" : "phone.fill")
                .foregroundStyle(.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.formattedNumber)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.tint)
                Text(contact.contactDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let actionURL = contact.actionURL {
                Button(contact.method.actionTitle) {
                    openURL(actionURL)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel("\(contact.method.actionTitle) \(contact.name)")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    if case .contacts(let contacts) = ResourceHubLibrary.categories.last?.content {
        VStack {
            ForEach(contacts.prefix(3)) { contact in
                EmergencyContactRowView(contact: contact)
            }
        }
        .padding()
    }
}
