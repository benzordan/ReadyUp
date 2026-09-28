//
//  PreparednessScoringTests.swift
//  ReadyUpTests
//

import Testing
@testable import ReadyUp

struct PreparednessScoringTests {

    @Test func zeroPointsIsStarterTier() {
        #expect(PreparednessScoring.tier(for: 0) == .starter)
    }

    @Test func negativePointsDefensivelyClampsToStarter() {
        #expect(PreparednessScoring.tier(for: -50) == .starter)
    }

    @Test func pointsJustBelowPreparedThresholdStaysStarter() {
        #expect(PreparednessScoring.tier(for: 99) == .starter)
    }

    @Test func preparedThresholdBoundaryEntersPreparedTier() {
        #expect(PreparednessScoring.tier(for: 100) == .prepared)
    }

    @Test func pointsJustBelowResilientThresholdStaysPrepared() {
        #expect(PreparednessScoring.tier(for: 249) == .prepared)
    }

    @Test func resilientThresholdBoundaryEntersResilientTier() {
        #expect(PreparednessScoring.tier(for: 250) == .resilient)
    }

    @Test func guardianThresholdBoundaryEntersGuardianTier() {
        #expect(PreparednessScoring.tier(for: 500) == .guardian)
    }

    @Test func pointsWellAboveGuardianStaysGuardian() {
        #expect(PreparednessScoring.tier(for: 10_000) == .guardian)
    }

    @Test func progressHalfwayThroughStarterTier() {
        let progress = PreparednessScoring.progress(forPoints: 50)
        #expect(progress.tier == .starter)
        #expect(progress.nextTier == .prepared)
        #expect(progress.pointsIntoTier == 50)
        #expect(progress.pointsToNextTier == 50)
        #expect(progress.fractionToNextTier == 0.5)
    }

    @Test func progressAtTierBoundaryStartsNextTierAtZero() {
        let progress = PreparednessScoring.progress(forPoints: 100)
        #expect(progress.tier == .prepared)
        #expect(progress.pointsIntoTier == 0)
        #expect(progress.fractionToNextTier == 0)
    }

    @Test func progressAtGuardianHasNoNextTierAndFullFraction() {
        let progress = PreparednessScoring.progress(forPoints: 500)
        #expect(progress.tier == .guardian)
        #expect(progress.nextTier == nil)
        #expect(progress.fractionToNextTier == 1.0)
        #expect(progress.pointsToNextTier == 0)
    }

    @Test func progressBeyondGuardianClampsFractionAtOne() {
        #expect(PreparednessScoring.progress(forPoints: 10_000).fractionToNextTier == 1.0)
    }
}
