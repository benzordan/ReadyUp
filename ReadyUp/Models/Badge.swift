//
//  Badge.swift
//  ReadyUp
//

import Foundation
import SwiftData

// Persisted record that a badge has been earned. The definition itself lives in
// BadgeLibrary; this only tracks which ones the user holds.
@Model
final class Badge {
    @Attribute(.unique) var id: String
    var earnedAt: Date

    init(id: String, earnedAt: Date = .now) {
        self.id = id
        self.earnedAt = earnedAt
    }
}
