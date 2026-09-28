//
//  AlertTone.swift
//  ReadyUp
//

import Foundation

// Generates the attention-interrupting tone the report requires before the
// spoken instruction.
//
// Synthesised rather than bundled: no audio asset ships with the app, a bundled
// one would carry a licensing question, and generating the samples here keeps
// the waveform a pure, unit-testable function instead of an opaque binary.
//
// Two alternating tones rather than a single steady one, because an alternating
// pair reads as an emergency signal while a constant beep reads as a
// notification.
enum AlertTone {

    static let sampleRate: Double = 44_100
    static let highFrequencyHertz: Double = 880
    static let lowFrequencyHertz: Double = 660
    static let alternationSeconds: Double = 0.25
    // Short of 1.0 so summing and playback cannot clip.
    static let amplitude: Float = 0.9

    // ========================================
    // static func samples(seconds: Double) -> [Float]
    // Builds the PCM waveform for the warning tone, alternating between the two frequencies every alternationSeconds. Pure function with no AVFoundation dependency, unit-tested for length, silence and clipping.
    // Returns: Mono float samples at sampleRate, or an empty array for a non-positive duration.
    // ========================================
    static func samples(seconds: Double) -> [Float] {
        guard seconds > 0 else { return [] }

        let frameCount = Int(sampleRate * seconds)
        let framesPerAlternation = Int(sampleRate * alternationSeconds)

        return (0..<frameCount).map { frame in
            let isHigh = framesPerAlternation > 0
                && (frame / framesPerAlternation).isMultiple(of: 2)
            let frequency = isHigh ? highFrequencyHertz : lowFrequencyHertz
            let phase = 2 * Double.pi * frequency * Double(frame) / sampleRate
            return amplitude * Float(sin(phase))
        }
    }
}
