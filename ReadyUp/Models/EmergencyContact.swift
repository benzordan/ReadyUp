//
//  EmergencyContact.swift
//  ReadyUp
//

import Foundation

// 70995 and 70999 are SMS-only lines for Deaf and Hard-of-Hearing users, so
// dialling them as a voice call would be wrong.
enum EmergencyContactMethod: String, Hashable {
    case call
    case sms

    var scheme: String {
        switch self {
        case .call: "tel"
        case .sms: "sms"
        }
    }

    var actionTitle: String {
        switch self {
        case .call: "Call"
        case .sms: "Text"
        }
    }
}

struct EmergencyContact: Identifiable, Hashable {
    let id: String
    let name: String
    // Officially formatted for display, e.g. "1800 280 0000".
    let formattedNumber: String
    let contactDescription: String
    let method: EmergencyContactMethod

    var actionURL: URL? {
        PhoneNumberFormatting.actionURL(from: formattedNumber, method: method)
    }
}
