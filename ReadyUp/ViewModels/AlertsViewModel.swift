//
//  AlertsViewModel.swift
//  ReadyUp
//

import Foundation
import Observation

enum AlertsFailure: Equatable {
    case locationDenied
    case locationUnavailable
    case outsideCoverage
    case networkUnavailable
}

enum AlertsLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(AlertsFailure)
}

// Resolves the user's location, fetches the hazard data for it, and classifies
// the result. Owns no ModelContext: alerts are deliberately not persisted —
// the app has no alert history, only the live classification.
@MainActor
@Observable
final class AlertsViewModel {

    private let locationService: LocationServicing
    private let hazardDataService: HazardDataServicing
    private let alertAudio: AlertAudioServicing
    private let notificationService: NotificationServicing
    private let stepInterval: Duration

    private(set) var state: AlertsLoadState = .idle
    // Kept across failures. A stale real reading is more useful to a stressed
    // user than an empty error screen, as long as the view never lets it
    // masquerade as live.
    private(set) var reading: HazardReading?

    // A simulated storm in progress. nil means the live reading is in charge.
    private(set) var escalation: HazardEscalation?
    private(set) var isShowingTakeover = false
    // Which hazard the takeover is warning about.
    private(set) var takeoverKind: HazardKind = .flashFlood
    private var isEscalating = false
    // The last overall tier the live data produced, so a refresh that stays at
    // High does not re-announce, while a genuine transition into High does.
    private var lastLiveOverall: AlertTier?

    var deliveryMode: AlertDeliveryMode { notificationService.deliveryMode }

    // The per-hazard picture. During a simulation the escalation replaces the
    // flood signal only; haze and heat stay live.
    var assessment: HazardAssessment? {
        let live = reading.map(RiskClassifier.assess)
        if let escalation {
            return HazardAssessment(flashFlood: escalation.tier, haze: live?.haze, heat: live?.heat)
        }
        return live
    }

    var tier: AlertTier? { assessment?.overall }

    var leadingKind: HazardKind { assessment?.leadingKind ?? .flashFlood }

    var rainfallText: String? {
        if let escalation { return String(format: "%.1f", escalation.millimetres) }
        return reading.map { String(format: "%.1f", $0.rainfallMillimetres) }
    }

    var isShowingStaleReading: Bool {
        if case .failed = state { return reading != nil }
        return false
    }

    init(
        locationService: LocationServicing,
        hazardDataService: HazardDataServicing,
        alertAudio: AlertAudioServicing = SilentAlertAudioService(),
        notificationService: NotificationServicing = SilentNotificationService(),
        stepInterval: Duration = HazardEscalation.stepInterval
    ) {
        self.locationService = locationService
        self.hazardDataService = hazardDataService
        self.alertAudio = alertAudio
        self.notificationService = notificationService
        self.stepInterval = stepInterval
    }

    // ========================================
    // func load() async
    // Resolves location then hazard data, classifying the result into the current tier. Ignores overlapping calls, since a pull-to-refresh can race the initial load. Never clears an existing reading on failure.
    // Returns: Nothing.
    // ========================================
    func load() async {
        guard state != .loading else { return }
        state = .loading

        let point: GeoPoint
        do {
            point = try await locationService.requestCurrentLocation()
        } catch {
            state = .failed(Self.failure(for: error))
            return
        }

        do {
            reading = try await hazardDataService.fetchReading(near: point)
            state = .loaded
            await announceLiveEscalationIfNeeded()
        } catch {
            state = .failed(Self.failure(for: error))
        }
    }

    // ========================================
    // private func announceLiveEscalationIfNeeded() async
    // Live readings drive the same announcement path as the demo: crossing into High fires the takeover, notification and audio exactly once, while staying at High across refreshes stays silent. A first load straight into High announces, since a user opening the app during an event must still be warned. Suppressed while a simulation is running.
    // Returns: Nothing.
    // ========================================
    private func announceLiveEscalationIfNeeded() async {
        guard let reading else { return }
        let live = RiskClassifier.assess(reading)
        let previous = lastLiveOverall
        lastLiveOverall = live.overall

        guard escalation == nil, previous != .high, live.overall == .high else { return }
        await announceHighTier(kind: live.leadingKind)
    }

    // MARK: - Escalation

    // ========================================
    // func startEscalation() async
    // Runs the simulated storm the report's prototype describes, stepping rainfall up until the classifier reaches High and then announcing once. Overlapping calls are ignored, so a double tap cannot produce two alarms.
    // Returns: Nothing.
    // ========================================
    func startEscalation() async {
        guard !isEscalating else { return }
        isEscalating = true
        defer { isEscalating = false }

        _ = await notificationService.requestAuthorization()
        escalation = HazardEscalation()

        for _ in 0..<HazardEscalation.stepCount {
            try? await Task.sleep(for: stepInterval)
            // stopEscalation clears this; bail rather than resurrecting it.
            guard var current = escalation else { return }

            let previousTier = current.tier
            current.advance()
            escalation = current

            if previousTier != .high && current.tier == .high {
                await announceHighTier(kind: .flashFlood)
            }
        }
    }

    // ========================================
    // func jumpEscalation(to tier: AlertTier) async
    // Skips the ramp and parks the simulation at the first step matching the tier, announcing if that lands on High. For demos that are short of time and for UI tests that should not wait out the animation.
    // Returns: Nothing.
    // ========================================
    func jumpEscalation(to tier: AlertTier) async {
        guard !isEscalating else { return }
        isEscalating = true
        defer { isEscalating = false }

        _ = await notificationService.requestAuthorization()
        escalation = HazardEscalation.jumping(to: tier)

        if tier == .high { await announceHighTier(kind: .flashFlood) }
    }

    // ========================================
    // private func announceHighTier(kind: HazardKind) async
    // Fires the High-tier warning across all three channels, worded for the hazard that caused it. The takeover is shown first and unconditionally, so neither a denied notification nor a failed audio session can leave the user with no warning at all. The notification is a Critical Alert when allowed, so it also sounds on a locked, silenced phone; with the app open, the in-app tone and spoken instruction carry the audio.
    // Returns: Nothing.
    // ========================================
    private func announceHighTier(kind: HazardKind) async {
        takeoverKind = kind
        isShowingTakeover = true

        await notificationService.deliverHighTierAlert(kind: kind, zoneName: reading?.zoneName ?? "your area", after: 0)
        await alertAudio.playAttentionTone(duration: .seconds(2))
        alertAudio.speak(kind.protectiveAction(at: .high))
    }

    // ========================================
    // func stopEscalation()
    // Abandons a simulation and returns to the live reading, silencing any warning already playing.
    // Returns: Nothing.
    // ========================================
    func stopEscalation() {
        escalation = nil
        alertAudio.stop()
    }

    // ========================================
    // func acknowledgeTakeover()
    // Dismisses the full-screen warning and stops the audio. Unconditional, so the takeover can always be escaped.
    // Returns: Nothing.
    // ========================================
    func acknowledgeTakeover() {
        isShowingTakeover = false
        alertAudio.stop()
    }

    // ========================================
    // func showTakeoverFromNotification()
    // Opens the takeover in response to a notification tap, without starting a simulation.
    // Returns: Nothing.
    // ========================================
    func showTakeoverFromNotification() {
        isShowingTakeover = true
    }

    // ========================================
    // func requestNotificationAuthorization() async -> AlertDeliveryMode
    // Asks for notification permission, including Critical Alerts, up front so a demo can confirm which delivery mode is live before triggering anything.
    // Returns: The delivery mode now in effect.
    // ========================================
    @discardableResult
    func requestNotificationAuthorization() async -> AlertDeliveryMode {
        await notificationService.requestAuthorization()
    }

    #if DEBUG
    // ========================================
    // func scheduleTestAlert(after seconds: TimeInterval) async
    // Schedules a High-tier notification with the system rather than a Task, so it still arrives after the phone is locked and the app suspended. This is the only way to check on a device that a Critical Alert sounds through silent mode and Focus. Debug panel only.
    // Returns: Nothing.
    // ========================================
    func scheduleTestAlert(after seconds: TimeInterval) async {
        _ = await notificationService.requestAuthorization()
        await notificationService.deliverHighTierAlert(
            kind: .flashFlood,
            zoneName: reading?.zoneName ?? "your area",
            after: seconds
        )
    }
    #endif

    // ========================================
    // func playWarningAudio() async
    // Plays the tone and spoken instruction on their own, so the audio can be demonstrated without the full escalation.
    // Returns: Nothing.
    // ========================================
    func playWarningAudio() async {
        await alertAudio.playAttentionTone(duration: .seconds(2))
        alertAudio.speak(HazardKind.flashFlood.protectiveAction(at: .high))
    }

    // ========================================
    // private static func failure(for error: Error) -> AlertsFailure
    // Maps a service error to the failure the view knows how to explain. An unrecognised error is treated as a network problem, which offers the user a retry rather than a dead end.
    // Returns: The matching AlertsFailure.
    // ========================================
    private static func failure(for error: Error) -> AlertsFailure {
        switch error {
        case LocationError.authorizationDenied, LocationError.authorizationRestricted:
            .locationDenied
        case LocationError.locationUnavailable, LocationError.requestAlreadyInFlight:
            .locationUnavailable
        case HazardDataError.outsideCoverage:
            .outsideCoverage
        default:
            .networkUnavailable
        }
    }
}
