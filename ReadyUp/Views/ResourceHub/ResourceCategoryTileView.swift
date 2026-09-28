//
//  ResourceCategoryTileView.swift
//  ReadyUp
//

import SwiftUI

struct ResourceCategoryTileView: View {
    let category: ResourceCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: category.iconSystemName)
                .font(.title)
                .foregroundStyle(.tint)

            Text(category.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Text(category.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title). \(category.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ResourceCategoryTileView(category: ResourceHubLibrary.categories[0])
        .padding()
}
