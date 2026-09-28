//
//  PhoneNumberFormatting.swift
//  ReadyUp
//

import Foundation

enum PhoneNumberFormatting {

    // ========================================
    // static func actionURL(from rawNumber: String, method: EmergencyContactMethod) -> URL?
    // Converts a display-formatted number such as "1800 280 0000" into a dialable tel: or sms: URL, stripping spaces and punctuation while preserving a leading country-code plus. Pure function, unit-tested against malformed input.
    // Returns: The dialable URL, or nil when the input contains no digits at all.
    // ========================================
    static func actionURL(from rawNumber: String, method: EmergencyContactMethod) -> URL? {
        let trimmed = rawNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasCountryCode = trimmed.hasPrefix("+")
        let digits = trimmed.filter(\.isNumber)

        guard !digits.isEmpty else { return nil }

        let dialable = hasCountryCode ? "+\(digits)" : digits
        return URL(string: "\(method.scheme):\(dialable)")
    }
}
