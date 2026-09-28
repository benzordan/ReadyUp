//
//  ResourceArticleDetailView.swift
//  ReadyUp
//

import SwiftUI

struct ResourceArticleDetailView: View {
    let article: ResourceArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(article.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundStyle(.tint)
                                .frame(width: 20, alignment: .leading)
                            Text(step)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Visible sourcing is the trust signal: guidance is curated and
                // traceable, not scattered or unattributed.
                Label(article.sourceCitation, systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    if case .articles(let articles) = ResourceHubLibrary.categories[1].content {
        NavigationStack {
            ResourceArticleDetailView(article: articles[2])
        }
    }
}
