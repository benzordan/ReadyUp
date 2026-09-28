//
//  AlertsViewModelTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

@MainActor
struct AlertsViewModelTests {

    private func makeViewModel(
        location: Result<GeoPoint, LocationError> = .success(.bedok),
        hazard: Result<HazardReading, HazardDataError> = .success(.previewLow),
        audio: SilentAlertAudioService = SilentAlertAudioService(),
        notifications: SilentNotificationService = SilentNotificationService()
    ) -> AlertsViewModel {
        AlertsViewModel(
            locationService: FixedLocationService(result: location),
            hazardDataService: FixedHazardDataService(result: hazard),
            alertAudio: audio,
            notificationService: notifications,
            // Escalation runs instantly in tests rather than taking 4.8 seconds.
            stepInterval: .zero
        )
    }

    // MARK: - Success

    @Test func loadPopulatesReadingAndTier() async {
        let viewModel = makeViewModel()
        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.reading?.zoneName == "Bedok")
        #expect(viewModel.tier == .low)
        #expect(viewModel.isShowingStaleReading == false)
    }

    @Test func startsIdleBeforeLoading() {
        let viewModel = makeViewModel()

        #expect(viewModel.state == .idle)
        #expect(viewModel.reading == nil)
        #expect(viewModel.tier == nil)
    }

    @Test func moderateRainfallClassifiesAsModerate() async {
        let viewModel = makeViewModel(hazard: .success(.preview(millimetres: 1.5)))
        await viewModel.load()

        #expect(viewModel.tier == .moderate)
    }

    @Test func heavyRainfallClassifiesAsHigh() async {
        let viewModel = makeViewModel(hazard: .success(.preview(millimetres: 6)))
        await viewModel.load()

        #expect(viewModel.tier == .high)
    }

    // Avoids an exact .5 tie, where printf rounds half-to-even and the result
    // would be testing IEEE rounding rather than this app's formatting.
    @Test func rainfallTextIsFormattedToOneDecimal() async {
        let viewModel = makeViewModel(hazard: .success(.preview(millimetres: 1.26)))
        await viewModel.load()

        #expect(viewModel.rainfallText == "1.3")
    }

    @Test func wholeRainfallValuesStillShowADecimal() async {
        let viewModel = makeViewModel(hazard: .success(.preview(millimetres: 6)))
        await viewModel.load()

        #expect(viewModel.rainfallText == "6.0")
    }

    // MARK: - Failures

    @Test func deniedLocationShowsDeniedFailureAndNoReading() async {
        let viewModel = makeViewModel(location: .failure(.authorizationDenied))
        await viewModel.load()

        #expect(viewModel.state == .failed(.locationDenied))
        #expect(viewModel.reading == nil)
        #expect(viewModel.isShowingStaleReading == false)
    }

    @Test func restrictedLocationShowsDeniedFailure() async {
        let viewModel = makeViewModel(location: .failure(.authorizationRestricted))
        await viewModel.load()

        #expect(viewModel.state == .failed(.locationDenied))
    }

    @Test func unavailableLocationShowsUnavailableFailure() async {
        let viewModel = makeViewModel(location: .failure(.locationUnavailable))
        await viewModel.load()

        #expect(viewModel.state == .failed(.locationUnavailable))
    }

    @Test func outsideCoverageShowsCoverageFailure() async {
        let viewModel = makeViewModel(hazard: .failure(.outsideCoverage))
        await viewModel.load()

        #expect(viewModel.state == .failed(.outsideCoverage))
    }

    @Test func requestFailureShowsNetworkFailure() async {
        let viewModel = makeViewModel(hazard: .failure(.requestFailed))
        await viewModel.load()

        #expect(viewModel.state == .failed(.networkUnavailable))
    }

    @Test func decodingFailureShowsNetworkFailure() async {
        let viewModel = makeViewModel(hazard: .failure(.decodingFailed))
        await viewModel.load()

        #expect(viewModel.state == .failed(.networkUnavailable))
    }

    @Test func locationFailureSkipsTheNetworkEntirely() async {
        // A hazard failure would be masked if location were not checked first.
        let viewModel = makeViewModel(
            location: .failure(.authorizationDenied),
            hazard: .failure(.requestFailed)
        )
        await viewModel.load()

        #expect(viewModel.state == .failed(.locationDenied))
    }

    // MARK: - Stale reading retention

    @Test func networkFailureAfterSuccessKeepsThePreviousReading() async {
        let hazard = FixedHazardDataService(result: .success(.previewModerate))
        let viewModel = AlertsViewModel(
            locationService: FixedLocationService(),
            hazardDataService: hazard
        )

        await viewModel.load()
        #expect(viewModel.tier == .moderate)

        hazard.result = .failure(.requestFailed)
        await viewModel.load()

        #expect(viewModel.state == .failed(.networkUnavailable))
        #expect(viewModel.reading != nil, "a stale reading beats an empty error screen")
        #expect(viewModel.tier == .moderate)
        #expect(viewModel.isShowingStaleReading, "the view must be able to mark it as stale")
    }

    // MARK: - Escalation

    @Test func escalationEndsAtHighAndShowsTheTakeover() async {
        let viewModel = makeViewModel()
        await viewModel.startEscalation()

        #expect(viewModel.tier == .high)
        #expect(viewModel.isShowingTakeover)
    }

    // The report requires the tone "immediately followed by" the spoken
    // instruction; this is the assertion that pins that ordering.
    @Test func highTierPlaysTheToneThenSpeaksTheAction() async {
        let audio = SilentAlertAudioService()
        let viewModel = makeViewModel(audio: audio)
        await viewModel.startEscalation()

        #expect(audio.playedEvents == [
            .tone(.seconds(2)),
            .speech(HazardKind.flashFlood.protectiveAction(at: .high))
        ])
    }

    @Test func spokenInstructionMatchesTheOnScreenGuidance() async {
        let audio = SilentAlertAudioService()
        await makeViewModel(audio: audio).startEscalation()

        #expect(audio.playedEvents.contains(.speech(HazardKind.flashFlood.protectiveAction(at: .high))))
    }

    // Four steps classify as High, but the user must be warned once.
    @Test func highTierAnnouncesExactlyOnceAcrossTheWholeRamp() async {
        let audio = SilentAlertAudioService()
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(audio: audio, notifications: notifications)
        await viewModel.startEscalation()

        #expect(notifications.deliveredZones.count == 1)
        #expect(audio.playedEvents.count { $0 == .tone(.seconds(2)) } == 1)
    }

    @Test func overlappingTriggersProduceOneWarning() async {
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(notifications: notifications)

        async let first: Void = viewModel.startEscalation()
        async let second: Void = viewModel.startEscalation()
        _ = await (first, second)

        #expect(notifications.deliveredZones.count == 1)
    }

    // The alert must never silently do nothing: with notifications refused the
    // visual and audible warnings still happen.
    @Test func deniedNotificationsStillShowTakeoverAndPlayAudio() async {
        let audio = SilentAlertAudioService()
        let notifications = SilentNotificationService(mode: .off)
        let viewModel = makeViewModel(audio: audio, notifications: notifications)
        await viewModel.startEscalation()

        #expect(notifications.deliveredZones.isEmpty)
        #expect(viewModel.isShowingTakeover)
        #expect(audio.playedEvents.contains(.tone(.seconds(2))))
    }

    @Test(arguments: [AlertDeliveryMode.critical, .standard, .off])
    func deliveryModeReflectsTheService(mode: AlertDeliveryMode) async {
        let viewModel = makeViewModel(notifications: SilentNotificationService(mode: mode))
        await viewModel.startEscalation()

        #expect(viewModel.deliveryMode == mode)
    }

    // A real High-tier announcement must go out immediately; only the debug
    // test alert is deferred to the system scheduler.
    @Test func liveAnnouncementIsDeliveredImmediately() async {
        let notifications = SilentNotificationService(mode: .critical)
        await makeViewModel(notifications: notifications).jumpEscalation(to: .high)

        #expect(notifications.deliveredDelays == [0])
    }

    @Test func testAlertIsScheduledWithTheSystemAndShowsNoTakeover() async {
        let notifications = SilentNotificationService(mode: .critical)
        let viewModel = makeViewModel(notifications: notifications)
        await viewModel.load()
        await viewModel.scheduleTestAlert(after: 10)

        #expect(notifications.deliveredDelays == [10])
        #expect(notifications.deliveredZones == ["Bedok"])
        #expect(viewModel.isShowingTakeover == false)
    }

    @Test func notificationUsesTheResolvedZoneName() async {
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(notifications: notifications)
        await viewModel.load()
        await viewModel.startEscalation()

        #expect(notifications.deliveredZones == ["Bedok"])
    }

    @Test func jumpingToHighAnnouncesImmediately() async {
        let audio = SilentAlertAudioService()
        let viewModel = makeViewModel(audio: audio)
        await viewModel.jumpEscalation(to: .high)

        #expect(viewModel.tier == .high)
        #expect(viewModel.isShowingTakeover)
        #expect(audio.playedEvents.contains(.tone(.seconds(2))))
    }

    @Test func jumpingToModerateDoesNotShowTheTakeover() async {
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(notifications: notifications)
        await viewModel.jumpEscalation(to: .moderate)

        #expect(viewModel.tier == .moderate)
        #expect(viewModel.isShowingTakeover == false)
        #expect(notifications.deliveredZones.isEmpty)
    }

    @Test func stoppingEscalationReturnsToTheLiveReadingAndSilencesAudio() async {
        let audio = SilentAlertAudioService()
        let viewModel = makeViewModel(audio: audio)
        await viewModel.load()
        await viewModel.jumpEscalation(to: .high)

        viewModel.stopEscalation()

        #expect(viewModel.escalation == nil)
        #expect(viewModel.tier == .low, "should fall back to the live reading")
        #expect(audio.playedEvents.contains(.stopped))
    }

    @Test func acknowledgingClearsTheTakeoverAndSilencesAudio() async {
        let audio = SilentAlertAudioService()
        let viewModel = makeViewModel(audio: audio)
        await viewModel.jumpEscalation(to: .high)

        viewModel.acknowledgeTakeover()

        #expect(viewModel.isShowingTakeover == false)
        #expect(audio.playedEvents.contains(.stopped))
    }

    @Test func notificationTapOpensTheTakeoverWithoutEscalating() {
        let viewModel = makeViewModel()
        viewModel.showTakeoverFromNotification()

        #expect(viewModel.isShowingTakeover)
        #expect(viewModel.escalation == nil)
    }

    // MARK: - Live-data alerting

    // The point of the whole pipeline: a real NEA reading crossing into High
    // must warn without any debug trigger involved.
    @Test func liveHighReadingAnnouncesOnLoad() async {
        let audio = SilentAlertAudioService()
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(
            hazard: .success(.preview(millimetres: 6)),
            audio: audio,
            notifications: notifications
        )
        await viewModel.load()

        #expect(viewModel.isShowingTakeover)
        #expect(viewModel.takeoverKind == .flashFlood)
        #expect(notifications.deliveredZones == ["Bedok"])
        #expect(audio.playedEvents.contains(.tone(.seconds(2))))
    }

    @Test func refreshingWhileStillHighDoesNotReAnnounce() async {
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(
            hazard: .success(.preview(millimetres: 6)),
            notifications: notifications
        )
        await viewModel.load()
        viewModel.acknowledgeTakeover()
        await viewModel.load()

        #expect(notifications.deliveredZones.count == 1)
        #expect(viewModel.isShowingTakeover == false)
    }

    @Test func liveModerateReadingDoesNotAnnounce() async {
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(
            hazard: .success(.preview(millimetres: 1.5)),
            notifications: notifications
        )
        await viewModel.load()

        #expect(viewModel.isShowingTakeover == false)
        #expect(notifications.deliveredZones.isEmpty)
    }

    @Test func liveHighHazeAnnouncesWithHazeGuidance() async {
        let audio = SilentAlertAudioService()
        let notifications = SilentNotificationService()
        let viewModel = makeViewModel(
            hazard: .success(.preview(millimetres: 0, psi: 250)),
            audio: audio,
            notifications: notifications
        )
        await viewModel.load()

        #expect(viewModel.isShowingTakeover)
        #expect(viewModel.takeoverKind == .haze)
        #expect(notifications.deliveredKinds == [.haze])
        #expect(audio.playedEvents.contains(.speech(HazardKind.haze.protectiveAction(at: .high))))
    }

    @Test func liveHighDuringASimulationStaysSilent() async {
        // The simulation owns the announcement while it runs; a live reading
        // arriving mid-demo must not fire a second warning.
        let notifications = SilentNotificationService()
        let hazard = FixedHazardDataService(result: .success(.preview(millimetres: 0)))
        let viewModel = AlertsViewModel(
            locationService: FixedLocationService(),
            hazardDataService: hazard,
            notificationService: notifications,
            stepInterval: .zero
        )
        await viewModel.jumpEscalation(to: .moderate)

        hazard.result = .success(.preview(millimetres: 6))
        await viewModel.load()

        #expect(notifications.deliveredZones.isEmpty)
        #expect(viewModel.isShowingTakeover == false)
    }

    @Test func escalationOverridesTheLiveRainfallReading() async {
        let viewModel = makeViewModel(hazard: .success(.preview(millimetres: 0)))
        await viewModel.load()
        #expect(viewModel.rainfallText == "0.0")

        await viewModel.jumpEscalation(to: .high)
        #expect(viewModel.rainfallText != "0.0")
        #expect(viewModel.tier == .high)
    }

    // Regression guard: with no simulation running, everything behaves exactly
    // as it did before escalation existed.
    @Test func withoutEscalationTierAndRainfallStillComeFromTheReading() async {
        let viewModel = makeViewModel(hazard: .success(.preview(millimetres: 1.5)))
        await viewModel.load()

        #expect(viewModel.escalation == nil)
        #expect(viewModel.tier == .moderate)
        #expect(viewModel.rainfallText == "1.5")
    }

    @Test func recoveringFromFailureClearsTheStaleFlag() async {
        let hazard = FixedHazardDataService(result: .failure(.requestFailed))
        let viewModel = AlertsViewModel(
            locationService: FixedLocationService(),
            hazardDataService: hazard
        )

        await viewModel.load()
        #expect(viewModel.isShowingStaleReading == false, "no reading yet, so nothing is stale")

        hazard.result = .success(.previewLow)
        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.isShowingStaleReading == false)
    }
}
