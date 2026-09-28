//
//  AlertAudioService.swift
//  ReadyUp
//

import Foundation
import AVFoundation

enum AlertAudioEvent: Equatable {
    case tone(Duration)
    case speech(String)
    case stopped
}

// Deliberately separate from SoundServicing. Gamification chimes are
// fire-and-forget, respect the silent switch and need no session; a life-safety
// warning configures an audio session, plays over the silent switch, must be
// interruptible, and sequences two stages. Merging the two would also hand the
// quiz screen the ability to fire an emergency alarm.
//
// Two methods rather than one playWarning(): the report requires the tone
// "immediately followed by" the spoken instruction, and only a two-call
// protocol lets a test assert that ordering.
protocol AlertAudioServicing {
    func playAttentionTone(duration: Duration) async
    func speak(_ instruction: String)
    func stop()
}

final class SystemAlertAudioService: AlertAudioServicing {

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    // Stored, never local: a synthesizer stops speaking when it deallocates.
    private let synthesizer = AVSpeechSynthesizer()

    private var isEngineConfigured = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // ========================================
    // func playAttentionTone(duration: Duration) async
    // Plays the looping two-tone warning for the given duration. Every audio failure is swallowed rather than thrown: an audio problem must never stop the caller from showing the visual alert.
    // Returns: Nothing.
    // ========================================
    func playAttentionTone(duration: Duration) async {
        activateSession()

        guard let buffer = makeToneBuffer() else { return }
        prepareEngineIfNeeded(format: buffer.format)

        // Explicit completion handler picks the non-async overload; the async
        // one would only return when the loop ends, which for .loops is never.
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()

        // Task.sleep rather than a completion delegate: it is cancellation-safe
        // by construction, so stop() mid-play cannot strand a continuation.
        try? await Task.sleep(for: duration)

        player.stop()
    }

    // ========================================
    // func speak(_ instruction: String)
    // Speaks the protective action aloud so the required action reaches a user who has not looked at the screen.
    // Returns: Nothing.
    // ========================================
    func speak(_ instruction: String) {
        activateSession()

        let utterance = AVSpeechUtterance(string: instruction)
        // No en-SG system voice exists; en-GB is the closest match for
        // Singaporean English spelling and rhythm.
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    // ========================================
    // func stop()
    // Silences the warning completely: tone, speech and the audio session. All three matter, or acknowledging the alert leaves the phone still talking.
    // Returns: Nothing.
    // ========================================
    func stop() {
        player.stop()
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // ========================================
    // private func activateSession()
    // Configures playback so the warning is heard over the ring/silent switch and ducks other audio rather than competing with it. Failures are ignored by design.
    // Returns: Nothing.
    // ========================================
    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)
    }

    private func prepareEngineIfNeeded(format: AVAudioFormat) {
        guard !isEngineConfigured else {
            if !engine.isRunning { try? engine.start() }
            return
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
        isEngineConfigured = true
    }

    private func makeToneBuffer() -> AVAudioPCMBuffer? {
        let samples = AlertTone.samples(seconds: AlertTone.alternationSeconds * 2)
        guard !samples.isEmpty,
              let format = AVAudioFormat(
                standardFormatWithSampleRate: AlertTone.sampleRate,
                channels: 1
              ),
              let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(samples.count)
              ),
              let channel = buffer.floatChannelData?[0] else { return nil }

        for (index, sample) in samples.enumerated() { channel[index] = sample }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        return buffer
    }

    // Stops on interruption but deliberately does not resume: an alarm
    // restarting by itself after a phone call is worse than silence, and the
    // takeover screen is still on display either way.
    @objc private func handleInterruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
        stop()
    }
}

// MARK: - Test double

// Records what would have been played, so tests can assert the tone precedes
// the speech, and so previews and UI tests stay silent.
final class SilentAlertAudioService: AlertAudioServicing {
    private(set) var playedEvents: [AlertAudioEvent] = []

    func playAttentionTone(duration: Duration) async {
        playedEvents.append(.tone(duration))
    }

    func speak(_ instruction: String) {
        playedEvents.append(.speech(instruction))
    }

    func stop() {
        playedEvents.append(.stopped)
    }
}
