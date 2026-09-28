//
//  NotificationService.swift
//  ReadyUp
//

import Foundation
import UserNotifications

// What the system will actually do with a High-tier warning. Three states
// rather than a Bool, because "allowed" and "will sound through silent mode"
// are different guarantees and the app must never imply the stronger one.
enum AlertDeliveryMode: Equatable {
    // Sounds through the ring/silent switch and Focus, at full volume.
    case critical
    // An ordinary notification: silenced by the ring switch and Focus.
    case standard
    // Notifications refused; only the in-app warning remains.
    case off

    var displayName: String {
        switch self {
        case .critical: "Critical Alerts"
        case .standard: "Standard notifications"
        case .off: "Notifications off"
        }
    }
}

protocol NotificationServicing: AnyObject {
    var deliveryMode: AlertDeliveryMode { get }
    func requestAuthorization() async -> AlertDeliveryMode
    func deliverHighTierAlert(kind: HazardKind, zoneName: String, after delay: TimeInterval) async
}

// Posts the High-tier warning as a Critical Alert when the user allows it, so it
// sounds on a locked, silenced phone — the case a stressed user is least able to
// catch — and as an ordinary notification otherwise.
//
// Critical Alerts need Apple's approval of the
// com.apple.developer.usernotifications.critical-alerts entitlement
// (ReadyUp.entitlements) plus the user's separate consent. The service never
// assumes either: it reads back what was actually granted.
final class SystemNotificationService: NSObject, NotificationServicing, UNUserNotificationCenterDelegate {

    private let center = UNUserNotificationCenter.current()
    private(set) var deliveryMode: AlertDeliveryMode = .off

    // Set by the composition root so a notification tap can open the takeover.
    var onAlertTapped: (() -> Void)?

    // ========================================
    // func requestAuthorization() async -> AlertDeliveryMode
    // Asks for notification permission including Critical Alerts, then reads the settings back rather than trusting the request's Bool: the Bool cannot say whether the critical part was granted, and without the entitlement iOS drops that option silently. Safe to call repeatedly; iOS returns the existing decision without re-prompting.
    // Returns: The delivery mode now in effect.
    // ========================================
    func requestAuthorization() async -> AlertDeliveryMode {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert])

        let settings = await center.notificationSettings()
        let isAuthorized = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
        deliveryMode = if settings.criticalAlertSetting == .enabled {
            .critical
        } else if isAuthorized {
            .standard
        } else {
            .off
        }
        return deliveryMode
    }

    // ========================================
    // func deliverHighTierAlert(kind: HazardKind, zoneName: String, after delay: TimeInterval) async
    // Posts the High-tier warning for the given hazard, as a Critical Alert at full volume when allowed. A positive delay hands the timing to the system rather than a Task, so the alert still arrives after the phone is locked and the app suspended. Wording comes from the shared HazardKind table so the notification and the screen cannot disagree.
    // Returns: Nothing.
    // ========================================
    func deliverHighTierAlert(kind: HazardKind, zoneName: String, after delay: TimeInterval) async {
        guard deliveryMode != .off else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(kind.warningName) — \(zoneName)"
        content.body = kind.protectiveAction(at: .high)
        content.userInfo = ["route": "takeover"]
        if deliveryMode == .critical {
            content.interruptionLevel = .critical
            content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
        } else {
            content.interruptionLevel = .active
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: "high-tier-alert",
            content: content,
            trigger: delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        )
        try? await center.add(request)
    }

    // Delegate callbacks are nonisolated under the project's MainActor-by-default
    // isolation, so each hops explicitly, matching CoreLocationService.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let isTakeover = response.notification.request.content.userInfo["route"] as? String == "takeover"
        Task { @MainActor in
            if isTakeover { onAlertTapped?() }
            completionHandler()
        }
    }

    // With the app open, the banner still shows so a demo can see the
    // notification fire, but its sound is dropped: the in-app tone and spoken
    // instruction are already playing, and a second alarm on top would make the
    // instruction hard to hear. Locked or backgrounded, the system plays it.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}

// MARK: - Test double

final class SilentNotificationService: NotificationServicing {
    var deliveryMode: AlertDeliveryMode
    private(set) var deliveredZones: [String] = []
    private(set) var deliveredKinds: [HazardKind] = []
    private(set) var deliveredDelays: [TimeInterval] = []

    init(mode: AlertDeliveryMode = .standard) {
        self.deliveryMode = mode
    }

    func requestAuthorization() async -> AlertDeliveryMode {
        deliveryMode
    }

    func deliverHighTierAlert(kind: HazardKind, zoneName: String, after delay: TimeInterval) async {
        guard deliveryMode != .off else { return }
        deliveredZones.append(zoneName)
        deliveredKinds.append(kind)
        deliveredDelays.append(delay)
    }
}
