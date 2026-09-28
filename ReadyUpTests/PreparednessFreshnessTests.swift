//
//  PreparednessFreshnessTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

// Boundary coverage for the decay curve. Every case pins an exact date offset
// rather than relying on the real clock, so these are deterministic.
struct PreparednessFreshnessTests {

    private let reference = Date(timeIntervalSince1970: 1_800_000_000)
    private let tolerance = 0.0001

    private func makeMission(
        intervalDays: Int = 180,
        points: Int = 30,
        completedDaysAgo: Double?
    ) -> Mission {
        Mission(
            id: "test.mission",
            title: "Test",
            missionDescription: "Test",
            kind: .task,
            pointValue: points,
            refreshIntervalDays: intervalDays,
            completionCount: completedDaysAgo == nil ? 0 : 1,
            completedAt: completedDaysAgo.map { reference.addingTimeInterval(-$0 * 86_400) }
        )
    }

    @Test func neverCompletedIsZeroValue() {
        let mission = makeMission(completedDaysAgo: nil)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .neverCompleted)
        #expect(abs(freshness.fraction - 0) < tolerance)
        #expect(freshness.contributedPoints == 0)
    }

    @Test func justCompletedIsFullValue() {
        let mission = makeMission(completedDaysAgo: 0)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .fresh)
        #expect(abs(freshness.fraction - 1.0) < tolerance)
        #expect(freshness.contributedPoints == 30)
    }

    @Test func dayBeforeFadeBeginsStaysFresh() {
        let mission = makeMission(completedDaysAgo: 89.9)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .fresh)
        #expect(abs(freshness.fraction - 1.0) < tolerance)
    }

    // The fresh window is inclusive at its upper bound by design.
    @Test func exactlyAtFadeBoundaryIsStillFresh() {
        let mission = makeMission(completedDaysAgo: 90)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .fresh)
        #expect(abs(freshness.fraction - 1.0) < tolerance)
        #expect(freshness.contributedPoints == 30)
    }

    @Test func midFadeIsHalfValue() {
        // 135 days of a 180-day interval is halfway through the 90-day fade.
        let mission = makeMission(completedDaysAgo: 135)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .fading)
        #expect(abs(freshness.fraction - 0.5) < tolerance)
        #expect(freshness.contributedPoints == 15)
    }

    @Test func justBeforeExpiryIsNearlyWorthless() {
        let mission = makeMission(completedDaysAgo: 179.9)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .fading)
        #expect(freshness.fraction < 0.01)
        #expect(freshness.contributedPoints == 0)
    }

    @Test func exactlyAtExpiryIsExpired() {
        let mission = makeMission(completedDaysAgo: 180)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .expired)
        #expect(abs(freshness.fraction - 0) < tolerance)
        #expect(freshness.contributedPoints == 0)
    }

    @Test func longPastExpiryStaysZero() {
        let mission = makeMission(completedDaysAgo: 3650)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .expired)
        #expect(abs(freshness.fraction - 0) < tolerance)
    }

    // A device clock change can put a completion in the future.
    @Test func futureCompletionClampsToFresh() {
        let mission = makeMission(completedDaysAgo: -5)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .fresh)
        #expect(abs(freshness.fraction - 1.0) < tolerance)
        #expect(freshness.contributedPoints == 30)
    }

    @Test func zeroIntervalNeverDecays() {
        let mission = makeMission(intervalDays: 0, completedDaysAgo: 9999)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.state == .fresh)
        #expect(freshness.contributedPoints == 30)
    }

    @Test func negativeIntervalNeverDecays() {
        let mission = makeMission(intervalDays: -30, completedDaysAgo: 9999)
        #expect(PreparednessFreshness.state(of: mission, asOf: reference) == .fresh)
    }

    @Test func quizIntervalDecaysOverTwelveMonths() {
        let fresh = makeMission(intervalDays: 365, points: 10, completedDaysAgo: 182)
        let fading = makeMission(intervalDays: 365, points: 10, completedDaysAgo: 273)
        let expired = makeMission(intervalDays: 365, points: 10, completedDaysAgo: 365)

        #expect(PreparednessFreshness.state(of: fresh, asOf: reference) == .fresh)
        #expect(PreparednessFreshness.contributedPoints(of: fresh, asOf: reference) == 10)
        #expect(PreparednessFreshness.state(of: fading, asOf: reference) == .fading)
        #expect(PreparednessFreshness.contributedPoints(of: fading, asOf: reference) == 5)
        #expect(PreparednessFreshness.contributedPoints(of: expired, asOf: reference) == 0)
    }

    @Test func daysUntilExpiryCountsDown() {
        let mission = makeMission(completedDaysAgo: 100)
        let freshness = PreparednessFreshness.freshness(of: mission, asOf: reference)

        #expect(freshness.daysUntilExpiry == 80)
    }

    @Test func completionCountWithoutDateIsTreatedAsNeverCompleted() {
        // Defensive: a row with a count but no date should not crash or score.
        let mission = Mission(
            id: "test.odd",
            title: "Test",
            kind: .task,
            pointValue: 30,
            completionCount: 1,
            completedAt: nil
        )
        #expect(PreparednessFreshness.state(of: mission, asOf: reference) == .neverCompleted)
        #expect(PreparednessFreshness.contributedPoints(of: mission, asOf: reference) == 0)
    }
}
