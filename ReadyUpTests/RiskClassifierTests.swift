//
//  RiskClassifierTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

// Full tier-boundary coverage, which the report names as the target for this
// classifier. Boundaries are asserted with .nextDown and .nextUp against the
// constants themselves, so "just below" and "just above" are the actual
// adjacent representable values rather than an arbitrary epsilon.
struct RiskClassifierTests {

    private let reference = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeReading(
        millimetres: Double,
        forecast: String = "Fair (Day)",
        psi: Int? = nil,
        celsius: Double? = nil
    ) -> HazardReading {
        HazardReading(
            zoneName: "Bedok",
            stationName: "Test Station",
            stationDistanceMetres: 500,
            rainfallMillimetres: millimetres,
            psi: psi,
            airTemperatureCelsius: celsius,
            forecast: forecast,
            observedAt: reference
        )
    }

    // MARK: - Rainfall boundaries

    @Test func zeroRainfallIsLow() {
        #expect(RiskClassifier.rainfallTier(millimetres: 0) == .low)
    }

    @Test func justBelowModerateThresholdIsLow() {
        let value = RiskClassifier.moderateThresholdMillimetres.nextDown
        #expect(RiskClassifier.rainfallTier(millimetres: value) == .low)
    }

    @Test func exactlyAtModerateThresholdIsModerate() {
        let value = RiskClassifier.moderateThresholdMillimetres
        #expect(RiskClassifier.rainfallTier(millimetres: value) == .moderate)
    }

    @Test func justAboveModerateThresholdIsModerate() {
        let value = RiskClassifier.moderateThresholdMillimetres.nextUp
        #expect(RiskClassifier.rainfallTier(millimetres: value) == .moderate)
    }

    @Test func justBelowHighThresholdIsModerate() {
        let value = RiskClassifier.highThresholdMillimetres.nextDown
        #expect(RiskClassifier.rainfallTier(millimetres: value) == .moderate)
    }

    @Test func exactlyAtHighThresholdIsHigh() {
        let value = RiskClassifier.highThresholdMillimetres
        #expect(RiskClassifier.rainfallTier(millimetres: value) == .high)
    }

    @Test func justAboveHighThresholdIsHigh() {
        let value = RiskClassifier.highThresholdMillimetres.nextUp
        #expect(RiskClassifier.rainfallTier(millimetres: value) == .high)
    }

    @Test func exactlyAtPlausibilityCeilingIsStillHigh() {
        // An extreme but physically possible reading must not be discarded.
        #expect(RiskClassifier.rainfallTier(millimetres: RiskClassifier.maxPlausibleMillimetres) == .high)
    }

    // MARK: - Untrustworthy readings

    // Each case is asserted twice: with an escalating forecast and a calm one.
    // Together they prove the fallback path is the forecast, not a hardcoded
    // .low, which would be a silent missed alert.
    private func expectFallsBackToForecast(_ millimetres: Double, _ label: String) {
        #expect(RiskClassifier.rainfallTier(millimetres: millimetres) == nil, "\(label) should not classify")
        #expect(
            RiskClassifier.classify(makeReading(millimetres: millimetres, forecast: "Thundery Showers")) == .moderate,
            "\(label) with a thundery forecast should follow the forecast"
        )
        #expect(
            RiskClassifier.classify(makeReading(millimetres: millimetres, forecast: "Fair (Day)")) == .low,
            "\(label) with a fair forecast should read low"
        )
    }

    @Test func negativeRainfallFallsBackToForecast() {
        expectFallsBackToForecast(-1, "negative rainfall")
    }

    @Test func notANumberRainfallFallsBackToForecast() {
        expectFallsBackToForecast(.nan, "NaN rainfall")
    }

    @Test func infiniteRainfallFallsBackToForecast() {
        expectFallsBackToForecast(.infinity, "infinite rainfall")
    }

    @Test func negativeInfinityRainfallFallsBackToForecast() {
        expectFallsBackToForecast(-.infinity, "negative infinite rainfall")
    }

    @Test func implausiblyLargeRainfallFallsBackToForecast() {
        expectFallsBackToForecast(150, "implausible rainfall")
    }

    // MARK: - Forecast combination

    @Test func thunderyForecastRaisesLowToModerate() {
        #expect(RiskClassifier.classify(makeReading(millimetres: 0, forecast: "Thundery Showers")) == .moderate)
    }

    @Test func heavyShowersForecastRaisesLowToModerate() {
        #expect(RiskClassifier.classify(makeReading(millimetres: 0, forecast: "Heavy Showers")) == .moderate)
    }

    // The invariant that keeps the false-positive rate near zero: a forecast is
    // a prediction, so it can raise awareness but never trigger the top tier.
    @Test func thunderyForecastNeverProducesHigh() {
        #expect(RiskClassifier.forecastTier("Heavy Thundery Showers") == .moderate)
        #expect(RiskClassifier.classify(makeReading(millimetres: 0, forecast: "Heavy Thundery Showers")) == .moderate)
    }

    @Test func forecastNeverLowersTheMeasuredTier() {
        #expect(RiskClassifier.classify(makeReading(millimetres: 5, forecast: "Fair (Day)")) == .high)
    }

    @Test func fairForecastWithNoRainIsLow() {
        #expect(RiskClassifier.classify(makeReading(millimetres: 0, forecast: "Fair (Day)")) == .low)
    }

    @Test func forecastMatchingIsCaseInsensitive() {
        #expect(RiskClassifier.forecastTier("THUNDERY SHOWERS") == .moderate)
        #expect(RiskClassifier.forecastTier("thundery showers") == .moderate)
    }

    @Test func emptyForecastIsLow() {
        // An unmatched area name yields no forecast text; the rainfall reading
        // still drives the tier.
        #expect(RiskClassifier.forecastTier("") == .low)
        #expect(RiskClassifier.classify(makeReading(millimetres: 5, forecast: "")) == .high)
    }

    @Test func partlyCloudyIsNotEscalating() {
        #expect(RiskClassifier.forecastTier("Partly Cloudy (Day)") == .low)
    }

    // MARK: - Haze boundaries (24-hour PSI)

    @Test func psiUpToOneHundredIsLow() {
        #expect(RiskClassifier.hazeTier(psi: 0) == .low)
        #expect(RiskClassifier.hazeTier(psi: 55) == .low)
        #expect(RiskClassifier.hazeTier(psi: RiskClassifier.hazeModeratePSI - 1) == .low)
    }

    @Test func psiUnhealthyBandIsModerate() {
        #expect(RiskClassifier.hazeTier(psi: RiskClassifier.hazeModeratePSI) == .moderate)
        #expect(RiskClassifier.hazeTier(psi: RiskClassifier.hazeHighPSI - 1) == .moderate)
    }

    @Test func psiVeryUnhealthyBandIsHigh() {
        #expect(RiskClassifier.hazeTier(psi: RiskClassifier.hazeHighPSI) == .high)
        #expect(RiskClassifier.hazeTier(psi: RiskClassifier.maxPlausiblePSI) == .high)
    }

    @Test func offScalePSIDoesNotClassify() {
        #expect(RiskClassifier.hazeTier(psi: -1) == nil)
        #expect(RiskClassifier.hazeTier(psi: RiskClassifier.maxPlausiblePSI + 1) == nil)
    }

    // MARK: - Heat boundaries (air temperature)

    @Test func heatBoundariesClassifyCorrectly() {
        #expect(RiskClassifier.heatTier(celsius: 31) == .low)
        #expect(RiskClassifier.heatTier(celsius: RiskClassifier.heatModerateCelsius.nextDown) == .low)
        #expect(RiskClassifier.heatTier(celsius: RiskClassifier.heatModerateCelsius) == .moderate)
        #expect(RiskClassifier.heatTier(celsius: RiskClassifier.heatHighCelsius.nextDown) == .moderate)
        #expect(RiskClassifier.heatTier(celsius: RiskClassifier.heatHighCelsius) == .high)
    }

    @Test func implausibleTemperatureDoesNotClassify() {
        #expect(RiskClassifier.heatTier(celsius: .nan) == nil)
        #expect(RiskClassifier.heatTier(celsius: -5) == nil)
        #expect(RiskClassifier.heatTier(celsius: 60) == nil)
    }

    // MARK: - Combined assessment

    @Test func missingSecondaryFeedsLeaveOnlyTheFloodTier() {
        let assessment = RiskClassifier.assess(makeReading(millimetres: 0))

        #expect(assessment.haze == nil)
        #expect(assessment.heat == nil)
        #expect(assessment.overall == .low)
        #expect(assessment.leadingKind == .flashFlood)
    }

    @Test func highHazeDrivesTheOverallTier() {
        let assessment = RiskClassifier.assess(makeReading(millimetres: 0, psi: 250, celsius: 31))

        #expect(assessment.overall == .high)
        #expect(assessment.leadingKind == .haze)
    }

    @Test func flashFloodWinsATieForTheLeadingHazard() {
        // Both High: the fastest-onset hazard fronts the warning.
        let assessment = RiskClassifier.assess(makeReading(millimetres: 6, psi: 250))

        #expect(assessment.overall == .high)
        #expect(assessment.leadingKind == .flashFlood)
    }

    @Test func moderateHeatOutranksLowFlood() {
        let assessment = RiskClassifier.assess(makeReading(millimetres: 0, psi: 55, celsius: 34.5))

        #expect(assessment.overall == .moderate)
        #expect(assessment.leadingKind == .heat)
    }

    @Test func classifyIsTheOverallAcrossHazards() {
        #expect(RiskClassifier.classify(makeReading(millimetres: 0, psi: 250)) == .high)
        #expect(RiskClassifier.classify(makeReading(millimetres: 0)) == .low)
    }

    // MARK: - Tier and message definitions

    @Test func everyTierHasDistinctColourAndGuidance() {
        let tiers = AlertTier.allCases
        #expect(Set(tiers.map(\.displayName)).count == tiers.count)
        #expect(Set(tiers.map(\.iconSystemName)).count == tiers.count)
        for kind in HazardKind.allCases {
            #expect(Set(tiers.map { kind.situation(at: $0) }).count == tiers.count)
            #expect(Set(tiers.map { kind.protectiveAction(at: $0) }).count == tiers.count)
        }
    }

    @Test func tiersAreOrderedBySeverity() {
        #expect(AlertTier.low < AlertTier.moderate)
        #expect(AlertTier.moderate < AlertTier.high)
        #expect(max(AlertTier.low, AlertTier.high) == .high)
    }

    // Pins the wording to the report's table, so a copy edit that drifts from
    // the specification fails here rather than shipping.
    @Test func fullMessagesMatchTheSpecification() {
        func fullMessage(_ tier: AlertTier) -> String {
            "\(HazardKind.flashFlood.situation(at: tier)) \(HazardKind.flashFlood.protectiveAction(at: tier))"
        }

        #expect(fullMessage(.low) == "All clear. No action required.")
        #expect(fullMessage(.moderate)
            == "Heavy rain developing. Stay indoors and monitor, avoid low-lying areas.")
        #expect(fullMessage(.high)
            == "Flash flood risk. Move to higher ground now, avoid underpasses and canals.")
    }

    @Test func thresholdsDeriveFromStatedIntensities() {
        #expect(abs(RiskClassifier.moderateThresholdMillimetres - 10.0 / 12) < 0.0001)
        #expect(abs(RiskClassifier.highThresholdMillimetres - 50.0 / 12) < 0.0001)
        #expect(RiskClassifier.moderateThresholdMillimetres < RiskClassifier.highThresholdMillimetres)
    }
}
