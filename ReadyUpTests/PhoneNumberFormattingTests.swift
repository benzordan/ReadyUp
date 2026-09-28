//
//  PhoneNumberFormattingTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct PhoneNumberFormattingTests {

    private func tel(_ raw: String) -> String? {
        PhoneNumberFormatting.actionURL(from: raw, method: .call)?.absoluteString
    }

    @Test func shortEmergencyNumberProducesTelURL() {
        #expect(tel("995") == "tel:995")
    }

    @Test func spacedNumberStripsSpaces() {
        #expect(tel("1800 280 0000") == "tel:18002800000")
    }

    @Test func hyphenatedNumberStripsHyphens() {
        #expect(tel("1800-255-0000") == "tel:18002550000")
    }

    @Test func parenthesesAndDotsAreStripped() {
        #expect(tel("(65) 6262.6262") == "tel:6562626262")
    }

    @Test func leadingPlusIsPreservedAsCountryCode() {
        #expect(tel("+65 1800 280 0000") == "tel:+6518002800000")
    }

    @Test func smsMethodProducesSmsScheme() {
        #expect(PhoneNumberFormatting.actionURL(from: "70995", method: .sms)?.absoluteString == "sms:70995")
    }

    @Test func emptyStringReturnsNil() {
        #expect(tel("") == nil)
    }

    @Test func whitespaceOnlyStringReturnsNil() {
        #expect(tel("   \n  ") == nil)
    }

    @Test func nonNumericStringReturnsNil() {
        #expect(tel("Call us") == nil)
    }

    @Test func plusWithNoDigitsReturnsNil() {
        #expect(tel("+") == nil)
    }

    @Test func malformedInputNeverCrashes() {
        let adversarialInputs = [
            "!!!",
            "🚒🔥",
            "tel:995",
            String(repeating: "9", count: 5_000),
            "９９５",
            "\u{0000}995",
            "--- ---"
        ]

        for input in adversarialInputs {
            // Both methods must return without trapping; the value itself may be nil.
            _ = PhoneNumberFormatting.actionURL(from: input, method: .call)
            _ = PhoneNumberFormatting.actionURL(from: input, method: .sms)
        }
    }
}
