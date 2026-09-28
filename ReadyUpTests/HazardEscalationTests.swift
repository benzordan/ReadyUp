//
//  HazardEscalationTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct HazardEscalationTests {

    private let tolerance = 0.0001

    private var allSteps: [HazardEscalation] {
        (0...HazardEscalation.stepCount).map { HazardEscalation(stepIndex: $0) }
    }

    // MARK: - The ramp

    @Test func startsAtRestingRainfallAndLowTier() {
        let escalation = HazardEscalation()

        #expect(escalation.stepIndex == 0)
        #expect(abs(escalation.millimetres - HazardEscalation.restingMillimetres) < tolerance)
        #expect(escalation.tier == .low)
        #expect(escalation.isFinished == false)
    }

    @Test func advancingEveryStepReachesPeakAndHigh() {
        var escalation = HazardEscalation()
        for _ in 0..<HazardEscalation.stepCount { escalation.advance() }

        #expect(escalation.isFinished)
        #expect(abs(escalation.millimetres - HazardEscalation.peakMillimetres) < tolerance)
        #expect(escalation.tier == .high)
    }

    @Test func advancingPastTheEndIsANoOp() {
        var escalation = HazardEscalation()
        for _ in 0..<(HazardEscalation.stepCount + 10) { escalation.advance() }

        #expect(escalation.stepIndex == HazardEscalation.stepCount)
        #expect(abs(escalation.millimetres - HazardEscalation.peakMillimetres) < tolerance)
    }

    @Test func rainfallIncreasesMonotonically() {
        let values = allSteps.map(\.millimetres)
        for (earlier, later) in zip(values, values.dropFirst()) {
            #expect(later > earlier, "rainfall must climb, got \(earlier) then \(later)")
        }
    }

    // MARK: - Tier progression

    @Test func tierNeverDecreasesAcrossTheRamp() {
        let tiers = allSteps.map(\.tier)
        for (earlier, later) in zip(tiers, tiers.dropFirst()) {
            #expect(later >= earlier, "tier must not fall back during escalation")
        }
    }

    // The report's requirement, asserted directly: "the risk pill steps through
    // the three tiers".
    @Test func rampVisitsAllThreeTiersInOrder() {
        var seen: [AlertTier] = []
        for tier in allSteps.map(\.tier) where seen.last != tier {
            seen.append(tier)
        }

        #expect(seen == [.low, .moderate, .high], "got \(seen)")
    }

    // Tied to the classifier's own constants, never a hardcoded 4.167, so
    // retuning the thresholds cannot silently break the demo.
    @Test func tierChangesLandOnTheClassifiersThresholds() {
        let steps = allSteps
        guard let firstHigh = steps.first(where: { $0.tier == .high }),
              let lastModerate = steps.last(where: { $0.tier == .moderate }),
              let firstModerate = steps.first(where: { $0.tier == .moderate }),
              let lastLow = steps.last(where: { $0.tier == .low }) else {
            Issue.record("ramp did not produce all three tiers")
            return
        }

        #expect(firstHigh.millimetres >= RiskClassifier.highThresholdMillimetres)
        #expect(lastModerate.millimetres < RiskClassifier.highThresholdMillimetres)
        #expect(firstModerate.millimetres >= RiskClassifier.moderateThresholdMillimetres)
        #expect(lastLow.millimetres < RiskClassifier.moderateThresholdMillimetres)
    }

    @Test func peakClassifiesAsHighUnderTheRealClassifier() {
        #expect(RiskClassifier.rainfallTier(millimetres: HazardEscalation.peakMillimetres) == .high)
    }

    @Test func restingClassifiesAsLowUnderTheRealClassifier() {
        #expect(RiskClassifier.rainfallTier(millimetres: HazardEscalation.restingMillimetres) == .low)
    }

    // MARK: - Jumping

    @Test func jumpingToHighLandsOnAHighStep() {
        #expect(HazardEscalation.jumping(to: .high).tier == .high)
    }

    @Test func jumpingToModerateLandsOnAModerateStep() {
        #expect(HazardEscalation.jumping(to: .moderate).tier == .moderate)
    }

    @Test func jumpingToLowStaysAtTheStart() {
        #expect(HazardEscalation.jumping(to: .low).stepIndex == 0)
    }

    @Test func jumpingPicksTheEarliestMatchingStep() {
        let jumped = HazardEscalation.jumping(to: .high)
        let earlier = HazardEscalation(stepIndex: jumped.stepIndex - 1)

        #expect(earlier.tier != .high, "jump should land on the first High step")
    }

    // MARK: - Defensive construction

    @Test func stepIndexIsClampedIntoRange() {
        #expect(HazardEscalation(stepIndex: -5).stepIndex == 0)
        #expect(HazardEscalation(stepIndex: 999).stepIndex == HazardEscalation.stepCount)
    }
}
