//
//  PreparednessTier.swift
//  ReadyUp
//

import Foundation

enum PreparednessTier: Int, CaseIterable, Comparable, Codable {
    case starter = 0
    case prepared = 1
    case resilient = 2
    case guardian = 3

    var minimumPoints: Int {
        switch self {
        case .starter: 0
        case .prepared: 100
        case .resilient: 250
        case .guardian: 500
        }
    }

    var displayName: String {
        switch self {
        case .starter: "Starter"
        case .prepared: "Prepared"
        case .resilient: "Resilient"
        case .guardian: "Guardian"
        }
    }

    static func < (lhs: PreparednessTier, rhs: PreparednessTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
