//
//  SeededRandomNumberGenerator.swift
//  ReadyUp
//

import Foundation

// A deterministic RNG so drill selection can be exercised reproducibly by unit
// tests. SplitMix64: small, fast, and good enough for shuffling a mission list
// — this is not used for anything security-sensitive.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    // ========================================
    // mutating func next() -> UInt64
    // Produces the next value in the SplitMix64 sequence, advancing the internal state. Deterministic for a given seed, which is the whole point of this type.
    // Returns: The next pseudo-random 64-bit value.
    // ========================================
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
