//
//  RiskClassifier.swift
//  ReadyUp
//

import Foundation

// The per-hazard picture for one reading.
//
// Secondary hazards are Optional because their feeds can fail independently of
// rainfall: nil means "no usable signal", and the Alerts tab hides that row
// rather than showing a fabricated Low.
struct HazardAssessment: Equatable {
    let flashFlood: AlertTier
    let haze: AlertTier?
    let heat: AlertTier?

    var overall: AlertTier { max(flashFlood, max(haze ?? .low, heat ?? .low)) }

    // Which hazard the overall tier belongs to. Flash flood wins ties because
    // it is the fastest-onset hazard of the three.
    var leadingKind: HazardKind {
        if flashFlood == overall { return .flashFlood }
        if haze == overall { return .haze }
        return .heat
    }
}

// Maps hazard readings to alert tiers, one per hazard kind.
//
// Rainfall thresholds are anchored on standard meteorological intensity —
// light below 2.5mm/h, moderate 2.5 to 10, heavy 10 to 50, very heavy above 50
// — converted to NEA's five-minute totals. They are declared in mm per hour and
// derived, so the justification stays visible next to the numbers.
//
// High is set at the "very heavy" boundary rather than "heavy" because the
// report treats the two failure directions asymmetrically: a false positive
// erodes trust in the system, while a missed alert is a life-safety failure.
// Escalating on merely heavy rain would fire far too often in Singapore.
//
// Every function here is pure and takes its inputs directly, so the tier
// boundaries are unit-tested with no network or location involved.
enum RiskClassifier {

    static let readingsPerHour: Double = 12

    static let moderateIntensityMillimetresPerHour: Double = 10
    static let highIntensityMillimetresPerHour: Double = 50

    static let moderateThresholdMillimetres = moderateIntensityMillimetresPerHour / readingsPerHour
    static let highThresholdMillimetres = highIntensityMillimetresPerHour / readingsPerHour

    // 100mm in five minutes is 1,200mm/h — far beyond any recorded rainfall, so
    // it indicates a sensor fault rather than weather.
    static let maxPlausibleMillimetres: Double = 100

    static let escalatingForecastKeywords = ["thundery", "heavy rain", "heavy showers"]

    // ========================================
    // static func rainfallTier(millimetres: Double) -> AlertTier?
    // Maps a five-minute rainfall total to a tier using fixed thresholds, both inclusive at their lower bound. Pure function, unit-tested against every boundary; returns nil rather than guessing when the reading cannot be trusted.
    // Returns: The matching tier, or nil for a non-finite, negative, or implausibly large reading.
    // ========================================
    static func rainfallTier(millimetres: Double) -> AlertTier? {
        guard millimetres.isFinite,
              millimetres >= 0,
              millimetres <= maxPlausibleMillimetres else { return nil }

        if millimetres >= highThresholdMillimetres { return .high }
        if millimetres >= moderateThresholdMillimetres { return .moderate }
        return .low
    }

    // ========================================
    // static func forecastTier(_ forecast: String) -> AlertTier
    // Maps NEA's two-hour forecast text to a tier by keyword. Capped at moderate by construction: a forecast is a prediction, not a measurement, so it can raise awareness but must never on its own trigger a high-tier alert. Pure function, unit-tested.
    // Returns: .moderate when the forecast mentions thundery or heavy conditions, otherwise .low.
    // ========================================
    static func forecastTier(_ forecast: String) -> AlertTier {
        let lowercased = forecast.lowercased()
        let isEscalating = escalatingForecastKeywords.contains { lowercased.contains($0) }
        return isEscalating ? .moderate : .low
    }

    // MARK: - Haze (24-hour PSI)

    // NEA's health advisory bands: PSI 101-200 is "Unhealthy" and above 200
    // "Very unhealthy". The app's Moderate and High sit on those boundaries;
    // up to 100 NEA advises normal activities, so the app stays Low.
    static let hazeModeratePSI = 101
    static let hazeHighPSI = 201
    // The PSI scale is defined up to 500.
    static let maxPlausiblePSI = 500

    // ========================================
    // static func hazeTier(psi: Int) -> AlertTier?
    // Maps a 24-hour PSI to a tier on NEA's advisory bands. Pure function, unit-tested against every boundary.
    // Returns: The matching tier, or nil for a negative or off-scale value.
    // ========================================
    static func hazeTier(psi: Int) -> AlertTier? {
        guard (0...maxPlausiblePSI).contains(psi) else { return nil }
        if psi >= hazeHighPSI { return .high }
        if psi >= hazeModeratePSI { return .moderate }
        return .low
    }

    // MARK: - Heat (air temperature)

    // 34°C is a very warm day for Singapore; 36°C is within a degree of the
    // all-time record, so a station reading there is exceptional. Wet-bulb
    // globe temperature would be the better heat-stress measure, but NEA
    // publishes no public WBGT feed.
    static let heatModerateCelsius = 34.0
    static let heatHighCelsius = 36.0
    static let plausibleCelsiusRange = 0.0...50.0

    // ========================================
    // static func heatTier(celsius: Double) -> AlertTier?
    // Maps an air-temperature reading to a tier. Pure function, unit-tested against every boundary.
    // Returns: The matching tier, or nil for a non-finite or implausible reading.
    // ========================================
    static func heatTier(celsius: Double) -> AlertTier? {
        guard celsius.isFinite, plausibleCelsiusRange.contains(celsius) else { return nil }
        if celsius >= heatHighCelsius { return .high }
        if celsius >= heatModerateCelsius { return .moderate }
        return .low
    }

    // MARK: - Combined

    // ========================================
    // static func assess(_ reading: HazardReading) -> HazardAssessment
    // Classifies every hazard in the reading. Flash flood combines the measured rainfall with the forecast, taking whichever is higher; an untrustworthy rainfall reading degrades to the forecast alone rather than to .low, since a silent all-clear from bad data is the one failure the report treats as unacceptable. Missing secondary feeds yield nil tiers.
    // Returns: The per-hazard assessment.
    // ========================================
    static func assess(_ reading: HazardReading) -> HazardAssessment {
        let measured = rainfallTier(millimetres: reading.rainfallMillimetres) ?? .low
        return HazardAssessment(
            flashFlood: max(measured, forecastTier(reading.forecast)),
            haze: reading.psi.flatMap(hazeTier(psi:)),
            heat: reading.airTemperatureCelsius.flatMap(heatTier(celsius:))
        )
    }

    // ========================================
    // static func classify(_ reading: HazardReading) -> AlertTier
    // The single overall tier for a reading: the worst across all hazards.
    // Returns: The tier for this reading.
    // ========================================
    static func classify(_ reading: HazardReading) -> AlertTier {
        assess(reading).overall
    }
}
