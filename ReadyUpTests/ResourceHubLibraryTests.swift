//
//  ResourceHubLibraryTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct ResourceHubLibraryTests {

    private var allArticles: [ResourceArticle] {
        ResourceHubLibrary.categories.flatMap { category in
            if case .articles(let articles) = category.content { return articles }
            return []
        }
    }

    private var allContacts: [EmergencyContact] {
        ResourceHubLibrary.categories.flatMap { category in
            if case .contacts(let contacts) = category.content { return contacts }
            return []
        }
    }

    @Test func categoryCountFitsTheGrid() {
        #expect((5...7).contains(ResourceHubLibrary.categories.count))
    }

    @Test func allCategoryIDsAreUnique() {
        let ids = ResourceHubLibrary.categories.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func allCategoriesHaveAnIcon() {
        #expect(ResourceHubLibrary.categories.allSatisfy { !$0.iconSystemName.isEmpty })
    }

    @Test func allCategoriesHaveATitleAndSubtitle() {
        #expect(ResourceHubLibrary.categories.allSatisfy { !$0.title.isEmpty && !$0.subtitle.isEmpty })
    }

    @Test func allArticleIDsAreUniqueAcrossCategories() {
        let ids = allArticles.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyArticleCategoryHasAtLeastThreeArticles() {
        for category in ResourceHubLibrary.categories {
            guard case .articles(let articles) = category.content else { continue }
            #expect(articles.count >= 3, "\(category.id) has only \(articles.count) articles")
        }
    }

    @Test func everyArticleHasAtLeastTwoSteps() {
        for article in allArticles {
            #expect(article.steps.count >= 2, "\(article.id) has only \(article.steps.count) steps")
        }
    }

    @Test func everyArticleHasASummaryAndCitation() {
        for article in allArticles {
            #expect(!article.summary.isEmpty, "\(article.id) is missing a summary")
            #expect(!article.sourceCitation.isEmpty, "\(article.id) is missing a citation")
        }
    }

    @Test func everyArticleCitesTheHandbookWithAPageNumber() {
        for article in allArticles {
            #expect(article.sourceCitation.contains("SCDF"), "\(article.id) does not cite the handbook")
            #expect(article.sourceCitation.contains("p."), "\(article.id) has no page reference")
        }
    }

    @Test func exactlyOneContactsCategoryExists() {
        let contactCategories = ResourceHubLibrary.categories.filter {
            if case .contacts = $0.content { return true }
            return false
        }
        #expect(contactCategories.count == 1)
    }

    @Test func allContactIDsAreUnique() {
        let ids = allContacts.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // Catches a typo'd or malformed phone number in the curated data before it ships.
    @Test func everyContactProducesAValidActionURL() {
        for contact in allContacts {
            #expect(contact.actionURL != nil, "\(contact.id) produced no dialable URL")
        }
    }

    @Test func smsContactsUseTheSmsScheme() {
        for contact in allContacts where contact.method == .sms {
            #expect(contact.actionURL?.scheme == "sms", "\(contact.id) should use the sms scheme")
        }
    }

    @Test func callContactsUseTheTelScheme() {
        for contact in allContacts where contact.method == .call {
            #expect(contact.actionURL?.scheme == "tel", "\(contact.id) should use the tel scheme")
        }
    }

    // The two SMS lines exist specifically for Deaf and Hard-of-Hearing users, so
    // they must never be dialled as voice calls.
    @Test func deafAndHardOfHearingLinesAreTextNotCall() {
        let smsLineIDs = ["contact.70995", "contact.70999"]
        for id in smsLineIDs {
            let contact = allContacts.first { $0.id == id }
            #expect(contact?.method == .sms, "\(id) must be an SMS contact")
        }
    }

    @Test func theCoreEmergencyNumbersArePresent() {
        let numbers = Set(allContacts.map(\.formattedNumber))
        #expect(numbers.contains("995"))
        #expect(numbers.contains("999"))
    }
}
