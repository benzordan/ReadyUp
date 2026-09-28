//
//  ResourceHubView.swift
//  ReadyUp
//

import SwiftUI

struct ResourceHubView: View {
    // Fixed two columns rather than adaptive sizing, so the grid stays in a
    // predictable, scannable layout for a stressed user who rarely opens the app.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ResourceHubLibrary.categories) { category in
                        NavigationLink(value: category) {
                            ResourceCategoryTileView(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Resource Hub")
            .navigationDestination(for: ResourceCategory.self) { category in
                ResourceCategoryDetailView(category: category)
            }
            .navigationDestination(for: ResourceArticle.self) { article in
                ResourceArticleDetailView(article: article)
            }
        }
    }
}

#Preview {
    ResourceHubView()
}
