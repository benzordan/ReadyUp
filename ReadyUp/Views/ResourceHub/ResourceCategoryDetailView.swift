//
//  ResourceCategoryDetailView.swift
//  ReadyUp
//

import SwiftUI

struct ResourceCategoryDetailView: View {
    let category: ResourceCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch category.content {
                case .articles(let articles):
                    ForEach(articles) { article in
                        NavigationLink(value: article) {
                            ResourceArticleRowView(article: article)
                        }
                        .buttonStyle(.plain)
                    }

                case .contacts(let contacts):
                    ForEach(contacts) { contact in
                        EmergencyContactRowView(contact: contact)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ResourceCategoryDetailView(category: ResourceHubLibrary.categories[1])
    }
}
