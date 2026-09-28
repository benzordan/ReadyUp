//
//  ResourceArticle.swift
//  ReadyUp
//

import Foundation

struct ResourceArticle: Identifiable, Hashable {
    let id: String
    let title: String
    // One line, shown on the category list row.
    let summary: String
    let steps: [String]
    // Surfaced in the UI, not just in source: the visible trust signal that the
    // guidance comes from an authoritative, citable source.
    let sourceCitation: String
}
