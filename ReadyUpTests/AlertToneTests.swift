//
//  AlertToneTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct AlertToneTests {

    @Test func producesTheExpectedNumberOfSamples() {
        let samples = AlertTone.samples(seconds: 0.5)
        #expect(samples.count == Int(AlertTone.sampleRate * 0.5))
    }

    @Test func isNotSilent() {
        let peak = AlertTone.samples(seconds: 0.5).map(abs).max() ?? 0
        #expect(peak > 0.5, "a warning tone must actually be audible, peak was \(peak)")
    }

    @Test func doesNotClip() {
        let peak = AlertTone.samples(seconds: 0.5).map(abs).max() ?? 0
        #expect(peak <= 1.0, "samples above 1.0 would distort, peak was \(peak)")
    }

    @Test func alternatesBetweenTwoFrequencies() {
        // Zero crossings scale with frequency, so the two halves of one
        // alternation cycle must differ.
        let samples = AlertTone.samples(seconds: AlertTone.alternationSeconds * 2)
        let half = samples.count / 2

        let firstCrossings = crossings(in: Array(samples[0..<half]))
        let secondCrossings = crossings(in: Array(samples[half...]))

        #expect(firstCrossings != secondCrossings, "both halves used the same frequency")
        #expect(firstCrossings > secondCrossings, "the high tone should come first")
    }

    @Test func nonPositiveDurationProducesNoSamples() {
        #expect(AlertTone.samples(seconds: 0).isEmpty)
        #expect(AlertTone.samples(seconds: -1).isEmpty)
    }

    @Test func frequenciesAreInTheAudibleAttentionRange() {
        #expect(AlertTone.highFrequencyHertz > AlertTone.lowFrequencyHertz)
        #expect(AlertTone.lowFrequencyHertz > 300)
        #expect(AlertTone.highFrequencyHertz < 4_000)
    }

    private func crossings(in samples: [Float]) -> Int {
        zip(samples, samples.dropFirst()).count { ($0 < 0) != ($1 < 0) }
    }
}
