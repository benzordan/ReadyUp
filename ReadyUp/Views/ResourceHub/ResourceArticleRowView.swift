//
//  ResourceArticleRowView.swift
//  ReadyUp
//

import SwiftUI

struct ResourceArticleRowView: View {
    let article: ResourceArticle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    if case .articles(let articles) = ResourceHubLibrary.categories[1].content {
        VStack {
            ForEach(articles.prefix(2)) { article in
                ResourceArticleRowView(article: article)
            }
        }
        .padding()
    }
}
