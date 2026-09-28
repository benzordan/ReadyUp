//
//  HistoricalReplayTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

// The report's data-driven evaluation, executable: historical NEA readings
// replayed through the real classifier and pipeline, reporting the two metrics
// the testing plan names — correct-classification rate and false-positive rate.
//
// The dataset is station S909's full day of five-minute totals for
// 2026-08-02, captured from NEA's historical API (?date=2026-08-02). It was a
// genuine flash-flood profile: dry all day, then 0.2 → 5.2 → 11.6mm inside
// fifteen minutes. Each reading carries a hand-assigned expected tier from the
// published intensity bands (moderate ≥ 10mm/h, high ≥ 50mm/h ≙ 0.83/4.17mm
// per 5 min), frozen here as literals — so if the classifier's thresholds are
// ever retuned, this labelled day fails loudly instead of drifting silently.
struct HistoricalReplayTests {

    // The twelve readings on which any rain fell, in order. The remaining 276
    // five-minute intervals that day all read 0.0mm and are replayed
    // programmatically below rather than listed.
    private static let stormReadings: [(time: String, millimetres: Double, expected: AlertTier)] = [
        ("15:05", 0.2, .low),
        ("15:10", 5.2, .high),
        ("15:15", 11.6, .high),
        ("15:20", 6.4, .high),
        ("15:25", 6.6, .high),
        ("15:30", 1.4, .moderate),
        ("15:35", 0.2, .low),
        ("15:40", 0.8, .low),
        ("15:45", 4.8, .high),
        ("15:50", 1.4, .moderate),
        ("15:55", 0.4, .low),
        ("16:00", 0.2, .low),
    ]

    private static let dryReadingCount = 276

    private static var fullDay: [(millimetres: Double, expected: AlertTier)] {
        Array(repeating: (0.0, AlertTier.low), count: dryReadingCount)
            + stormReadings.map { ($0.millimetres, $0.expected) }
    }

    // MARK: - The report's two metrics

    @Test func correctClassificationRateIsOneHundredPercent() {
        let day = Self.fullDay
        let correct = day.count { RiskClassifier.rainfallTier(millimetres: $0.millimetres) == $0.expected }

        #expect(day.count == 288, "a full day of five-minute totals")
        #expect(Double(correct) / Double(day.count) == 1.0)
    }

    @Test func falsePositiveRateIsZero() {
        // A false positive: High fired on a reading below the very-heavy band.
        let falsePositives = Self.fullDay.count {
            RiskClassifier.rainfallTier(millimetres: $0.millimetres) == .high && $0.expected != .high
        }
        #expect(falsePositives == 0)
    }

    @Test func noMissedAlertsAcrossTheStorm() {
        // The asymmetric failure the report treats as worse than a false
        // positive: a very-heavy reading that does not classify High.
        let missed = Self.fullDay.count {
            $0.expected == .high && RiskClassifier.rainfallTier(millimetres: $0.millimetres) != .high
        }
        #expect(missed == 0)
    }

    @Test func stormOnsetEscalatesWithinOneInterval() {
        // 15:05 read 0.2mm (low); 15:10 read 5.2mm (high). The classifier must
        // make that jump in a single five-minute step — flash-flood onset does
        // not politely pass through Moderate.
        #expect(RiskClassifier.rainfallTier(millimetres: 0.2) == .low)
        #expect(RiskClassifier.rainfallTier(millimetres: 5.2) == .high)
    }

    // MARK: - Pipeline replay on real payloads

    // Trimmed but value-exact captures of the rainfall feed at two moments on
    // 2026-08-02: 14:00 (calm) and 15:15 (peak). Station list, coordinates and
    // readings are the API's own bytes for the four stations nearest S909.
    private static func rainfallPayload(timestamp: String, values: [String: Double]) -> String {
        """
        {"code":0,"errorMsg":null,"data":{
          "stations":[
            {"id":"S909","deviceId":"S909","name":"S909","location":{"latitude":1.30568,"longitude":103.90093}},
            {"id":"S113","deviceId":"S113","name":"Marine Parade Road","location":{"latitude":1.305,"longitude":103.9112}},
            {"id":"S78","deviceId":"S78","name":"Poole Road","location":{"latitude":1.307,"longitude":103.8907}},
            {"id":"S214","deviceId":"S214","name":"Tanjong Rhu","location":{"latitude":1.29911,"longitude":103.88289}}
          ],
          "readings":[{"timestamp":"\(timestamp)","data":[
            {"stationId":"S909","value":\(values["S909"]!)},
            {"stationId":"S113","value":\(values["S113"]!)},
            {"stationId":"S78","value":\(values["S78"]!)},
            {"stationId":"S214","value":\(values["S214"]!)}
          ]}],
          "readingType":"TB1 Rainfall 5 Minute Total F","readingUnit":"mm"}}
        """
    }

    // Live area coordinates from NEA's area_metadata for the zones this test
    // and the GPX route cross.
    private static let forecastPayload = """
    {"code":0,"errorMsg":null,"data":{
      "area_metadata":[
        {"name":"Tampines","label_location":{"latitude":1.345,"longitude":103.944}},
        {"name":"Bedok","label_location":{"latitude":1.321,"longitude":103.924}},
        {"name":"Marine Parade","label_location":{"latitude":1.297,"longitude":103.891}},
        {"name":"Kallang","label_location":{"latitude":1.312,"longitude":103.862}},
        {"name":"City","label_location":{"latitude":1.292,"longitude":103.844}},
        {"name":"Jurong West","label_location":{"latitude":1.34039,"longitude":103.705}}
      ],
      "items":[{"forecasts":[{"area":"Marine Parade","forecast":"Thundery Showers"}]}]}}
    """

    // A user standing at the storm station's coordinates.
    private let atStorm = GeoPoint(latitude: 1.30568, longitude: 103.90093)

    private func replay(values: [String: Double], timestamp: String) throws -> HazardReading {
        try NEAHazardDataService.makeReading(
            rainfallData: Data(Self.rainfallPayload(timestamp: timestamp, values: values).utf8),
            forecastData: Data(Self.forecastPayload.utf8),
            near: atStorm
        )
    }

    @Test func calmAfternoonClassifiesLowInTheRightZone() throws {
        // 14:00 that day: every station at zero, fair skies.
        let calmForecast = Self.forecastPayload.replacingOccurrences(
            of: "Thundery Showers", with: "Partly Cloudy (Day)")
        let reading = try NEAHazardDataService.makeReading(
            rainfallData: Data(Self.rainfallPayload(
                timestamp: "2026-08-02T14:00:00+08:00",
                values: ["S909": 0, "S113": 0, "S78": 0, "S214": 0]).utf8),
            forecastData: Data(calmForecast.utf8),
            near: atStorm
        )

        #expect(reading.zoneName == "Marine Parade")
        #expect(reading.stationName == "S909")
        #expect(RiskClassifier.classify(reading) == .low)
    }

    @Test func stormPeakClassifiesHighInTheRightZone() throws {
        // 15:15 that day: S909 at 11.6mm, Marine Parade Road at 10.8mm.
        let reading = try replay(
            values: ["S909": 11.6, "S113": 10.8, "S78": 2.2, "S214": 0],
            timestamp: "2026-08-02T15:15:00+08:00"
        )

        #expect(reading.zoneName == "Marine Parade")
        #expect(abs(reading.rainfallMillimetres - 11.6) < 0.0001)
        #expect(RiskClassifier.classify(reading) == .high)
    }

    // MARK: - GPX route zone resolution

    // The waypoints of SingaporeStormRoute.gpx (repo root), used with Xcode's
    // Simulate Location to drive the real CoreLocationService across zones.
    // This pins the route's coordinates to the zones they must resolve to, so
    // the manual GPX run and the automated expectation cannot disagree.
    private static let route: [(latitude: Double, longitude: Double, zone: String)] = [
        (1.345, 103.944, "Tampines"),
        (1.321, 103.924, "Bedok"),
        (1.30568, 103.90093, "Marine Parade"),
        (1.312, 103.862, "Kallang"),
        (1.292, 103.844, "City"),
        (1.34039, 103.705, "Jurong West"),
    ]

    @Test func everyRouteWaypointResolvesToItsExpectedZone() throws {
        for stop in Self.route {
            let reading = try NEAHazardDataService.makeReading(
                rainfallData: Data(Self.rainfallPayload(
                    timestamp: "2026-08-02T14:00:00+08:00",
                    values: ["S909": 0, "S113": 0, "S78": 0, "S214": 0]).utf8),
                forecastData: Data(Self.forecastPayload.utf8),
                near: GeoPoint(latitude: stop.latitude, longitude: stop.longitude)
            )
            #expect(reading.zoneName == stop.zone, "waypoint \(stop.zone)")
        }
    }
}
