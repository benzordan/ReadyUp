//
//  ResourceCategory.swift
//  ReadyUp
//

import Foundation

enum ResourceCategoryContent: Hashable {
    case articles([ResourceArticle])
    case contacts([EmergencyContact])
}

struct ResourceCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let iconSystemName: String
    let content: ResourceCategoryContent
}
