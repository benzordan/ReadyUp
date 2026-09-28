//
//  SoundService.swift
//  ReadyUp
//

import Foundation
import AudioToolbox

enum SoundEvent: Equatable {
    case correctAnswer
    case missionCompleted
    case badgeUnlocked
}

protocol SoundServicing {
    func playCorrectAnswer()
    func playMissionCompleted()
    func playBadgeUnlocked()
}

final class SystemSoundService: SoundServicing {
    // Built-in AudioToolbox tones. Swapping these for bundled .caf assets would
    // only touch this type.
    private let correctAnswerSoundID: SystemSoundID = 1103
    private let missionCompletedSoundID: SystemSoundID = 1025
    private let badgeUnlockedSoundID: SystemSoundID = 1013

    func playCorrectAnswer() { AudioServicesPlaySystemSound(correctAnswerSoundID) }
    func playMissionCompleted() { AudioServicesPlaySystemSound(missionCompletedSoundID) }
    func playBadgeUnlocked() { AudioServicesPlaySystemSound(badgeUnlockedSoundID) }
}

// Records events instead of playing them, so tests can assert on reward feedback
// and previews stay silent.
final class SilentSoundService: SoundServicing {
    private(set) var playedEvents: [SoundEvent] = []

    func playCorrectAnswer() { playedEvents.append(.correctAnswer) }
    func playMissionCompleted() { playedEvents.append(.missionCompleted) }
    func playBadgeUnlocked() { playedEvents.append(.badgeUnlocked) }
}
