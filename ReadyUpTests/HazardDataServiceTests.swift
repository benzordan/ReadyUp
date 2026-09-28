//
//  HazardDataServiceTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

// Fixtures are trimmed to three stations and three areas but are key-for-key
// identical to the live NEA responses, including the rainfall feed's camelCase
// against the forecast feed's snake_case and the +08:00 timestamps. That is
// what makes these tests pin the decoder strategy rather than assume it: a
// wrong keyDecodingStrategy or dateDecodingStrategy fails here instead of
// failing every fetch at runtime while the code still looks correct.
struct HazardDataServiceTests {

    private let bedok = GeoPoint(latitude: 1.321, longitude: 103.924)
    private let cupertino = GeoPoint(latitude: 37.3349, longitude: -122.0090)

    private static let rainfallJSON = """
    {"code":0,"errorMsg":null,"data":{
      "stations":[
        {"id":"S218","deviceId":"S218","name":"Bukit Batok Street 34","location":{"latitude":1.36491,"longitude":103.75065}},
        {"id":"S106","deviceId":"S106","name":"Pulau Ubin","location":{"longitude":103.96261,"latitude":1.4168}},
        {"id":"S43","deviceId":"S43","name":"Kim Chuan Road","location":{"latitude":1.3399,"longitude":103.8878}}
      ],
      "readings":[{"timestamp":"2026-08-02T06:05:00+08:00","data":[
        {"stationId":"S218","value":0},
        {"stationId":"S106","value":0.2},
        {"stationId":"S43","value":1.4}
      ]}],
      "readingType":"TB1 Rainfall 5 Minute Total F","readingUnit":"mm"}}
    """

    private static let forecastJSON = """
    {"code":0,"errorMsg":null,"data":{
      "area_metadata":[
        {"name":"Ang Mo Kio","label_location":{"latitude":1.375,"longitude":103.839}},
        {"name":"Bedok","label_location":{"latitude":1.321,"longitude":103.924}},
        {"name":"Jurong West","label_location":{"latitude":1.352,"longitude":103.697}}
      ],
      "items":[{"update_timestamp":"2026-08-02T05:56:00+08:00","timestamp":"2026-08-02T06:00:00+08:00",
        "valid_period":{"start":"2026-08-02T06:00:00+08:00","end":"2026-08-02T08:00:00+08:00","text":"6.00 am to 8.00 am"},
        "forecasts":[
          {"area":"Ang Mo Kio","forecast":"Partly Cloudy (Day)"},
          {"area":"Bedok","forecast":"Thundery Showers"},
          {"area":"Jurong West","forecast":"Fair (Day)"}
        ]}]}}
    """

    // Trimmed but shape-identical to the live PSI response: camelCase metadata
    // around a snake_case readings key, exactly as NEA serves it.
    private static let psiJSON = """
    {"code":0,"data":{
      "regionMetadata":[
        {"name":"west","labelLocation":{"longitude":103.7,"latitude":1.35735}},
        {"name":"east","labelLocation":{"longitude":103.94,"latitude":1.35735}},
        {"name":"central","labelLocation":{"longitude":103.82,"latitude":1.35735}}
      ],
      "items":[{"date":"2026-08-02","updatedTimestamp":"2026-08-02T06:09:00+08:00","timestamp":"2026-08-02T06:00:00+08:00",
        "readings":{"psi_twenty_four_hourly":{"west":72,"east":69,"central":79},
                    "pm25_twenty_four_hourly":{"west":31,"east":28,"central":37}}}]},
      "errorMsg":""}
    """

    // The air-temperature feed shares the rainfall feed's stations-plus-readings shape.
    private static let airTemperatureJSON = """
    {"code":0,"data":{
      "stations":[
        {"id":"S43","deviceId":"S43","name":"Kim Chuan Road","location":{"latitude":1.3399,"longitude":103.8878}},
        {"id":"S117","deviceId":"S117","name":"Banyan Road","location":{"latitude":1.2542,"longitude":103.6741}}
      ],
      "readings":[{"timestamp":"2026-08-02T06:05:00+08:00","data":[
        {"stationId":"S43","value":34.2},
        {"stationId":"S117","value":29.8}
      ]}],
      "readingType":"DBT 1M F","readingUnit":"deg C"}}
    """

    private func data(_ json: String) -> Data { Data(json.utf8) }

    private func makeReading(
        rainfall: String? = nil,
        forecast: String? = nil,
        psi: String? = nil,
        airTemperature: String? = nil,
        near point: GeoPoint? = nil
    ) throws -> HazardReading {
        try NEAHazardDataService.makeReading(
            rainfallData: data(rainfall ?? Self.rainfallJSON),
            forecastData: data(forecast ?? Self.forecastJSON),
            psiData: psi.map(data),
            airTemperatureData: airTemperature.map(data),
            near: point ?? bedok
        )
    }

    // MARK: - Decoding the live payload shapes

    @Test func decodesBothLivePayloadShapes() throws {
        let reading = try makeReading()

        #expect(reading.zoneName == "Bedok")
        #expect(reading.stationName == "Kim Chuan Road")
        #expect(reading.forecast == "Thundery Showers")
    }

    @Test func observedAtMatchesTheFeedTimestamp() throws {
        let reading = try makeReading()

        // 2026-08-02T06:05:00+08:00
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 2
        components.hour = 6
        components.minute = 5
        components.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        let expected = Calendar(identifier: .gregorian).date(from: components)

        #expect(reading.observedAt == expected)
    }

    @Test func selectsTheNearestStationNotTheFirst() throws {
        // Kim Chuan Road is nearest Bedok; Bukit Batok is listed first.
        let reading = try makeReading()
        #expect(reading.stationName == "Kim Chuan Road")
        #expect(abs(reading.rainfallMillimetres - 1.4) < 0.0001)
    }

    @Test func selectsTheNearestAreaForTheZoneName() throws {
        let jurongWest = GeoPoint(latitude: 1.352, longitude: 103.697)
        let reading = try makeReading(near: jurongWest)

        #expect(reading.zoneName == "Jurong West")
        #expect(reading.forecast == "Fair (Day)")
    }

    @Test func reportsTheDistanceToTheChosenStation() throws {
        let reading = try makeReading()
        #expect(reading.stationDistanceMetres > 0)
        #expect(reading.stationDistanceMetres < HazardGeography.maxCoverageDistanceMetres)
    }

    // MARK: - Secondary feeds (PSI and air temperature)

    @Test func decodesPSIForTheNearestRegion() throws {
        // Bedok's nearest PSI region is east.
        let reading = try makeReading(psi: Self.psiJSON)
        #expect(reading.psi == 69)
    }

    @Test func decodesAirTemperatureFromTheNearestStation() throws {
        let reading = try makeReading(airTemperature: Self.airTemperatureJSON)
        #expect(reading.airTemperatureCelsius == 34.2)
    }

    @Test func missingSecondaryPayloadsYieldNilFields() throws {
        let reading = try makeReading()
        #expect(reading.psi == nil)
        #expect(reading.airTemperatureCelsius == nil)
    }

    // A broken haze or temperature payload must never break flood alerting.
    @Test func malformedSecondaryPayloadsDegradeToNilRatherThanThrowing() throws {
        let reading = try makeReading(psi: "{not json", airTemperature: "")
        #expect(reading.psi == nil)
        #expect(reading.airTemperatureCelsius == nil)
        #expect(reading.zoneName == "Bedok")
    }

    @Test func secondaryPayloadWithAPIErrorCodeDegradesToNil() throws {
        let json = """
        {"code":4,"errorMsg":"rate limited","data":{"regionMetadata":[],"items":[]}}
        """
        let reading = try makeReading(psi: json)
        #expect(reading.psi == nil)
    }

    // MARK: - Failure modes

    @Test func emptyStationListThrowsNoData() throws {
        let json = """
        {"code":0,"data":{"stations":[],"readings":[{"timestamp":"2026-08-02T06:05:00+08:00","data":[]}]}}
        """
        #expect(throws: HazardDataError.noData) { try makeReading(rainfall: json) }
    }

    @Test func emptyReadingsBlockThrowsNoData() throws {
        let json = """
        {"code":0,"data":{"stations":[{"id":"S43","deviceId":"S43","name":"Kim Chuan Road","location":{"latitude":1.3399,"longitude":103.8878}}],"readings":[]}}
        """
        #expect(throws: HazardDataError.noData) { try makeReading(rainfall: json) }
    }

    // A fabricated 0.0 here would render a green "All clear" from missing data,
    // which is the one failure the report treats as unacceptable.
    @Test func stationMissingFromReadingsThrowsNoDataRatherThanZero() throws {
        let json = """
        {"code":0,"data":{
          "stations":[{"id":"S43","deviceId":"S43","name":"Kim Chuan Road","location":{"latitude":1.3399,"longitude":103.8878}}],
          "readings":[{"timestamp":"2026-08-02T06:05:00+08:00","data":[{"stationId":"S218","value":0}]}]}}
        """
        #expect(throws: HazardDataError.noData) { try makeReading(rainfall: json) }
    }

    @Test func malformedJSONThrowsDecodingFailed() throws {
        #expect(throws: HazardDataError.decodingFailed) { try makeReading(rainfall: "{not json") }
    }

    @Test func emptyDataThrowsDecodingFailed() throws {
        #expect(throws: HazardDataError.decodingFailed) { try makeReading(rainfall: "") }
    }

    // Both endpoints answer HTTP 200 with a non-zero code on an API-level error.
    @Test func nonZeroAPICodeThrowsRequestFailed() throws {
        let json = """
        {"code":4,"errorMsg":"rate limited","data":{"stations":[],"readings":[]}}
        """
        #expect(throws: HazardDataError.requestFailed) { try makeReading(rainfall: json) }
    }

    @Test func cupertinoThrowsOutsideCoverage() throws {
        #expect(throws: HazardDataError.outsideCoverage) { try makeReading(near: cupertino) }
    }

    @Test func unmatchedAreaLeavesForecastEmptyRatherThanFailing() throws {
        let json = """
        {"code":0,"data":{
          "area_metadata":[{"name":"Bedok","label_location":{"latitude":1.321,"longitude":103.924}}],
          "items":[{"forecasts":[{"area":"Somewhere Else","forecast":"Fair (Day)"}]}]}}
        """
        let reading = try makeReading(forecast: json)

        #expect(reading.zoneName == "Bedok")
        #expect(reading.forecast.isEmpty)
    }

    // MARK: - Launch-argument fake

    @Test func simulateRainfallArgumentIsParsed() async throws {
        let service = FixedHazardDataService.fromLaunchArguments(["-uitesting", "-simulateRainfall", "6.0"])
        let reading = try await service.fetchReading(near: bedok)

        #expect(abs(reading.rainfallMillimetres - 6.0) < 0.0001)
        #expect(RiskClassifier.classify(reading) == .high)
    }

    @Test func simulatePSIAndTemperatureArgumentsAreParsed() async throws {
        let service = FixedHazardDataService.fromLaunchArguments(
            ["-uitesting", "-simulatePSI", "250", "-simulateTemperature", "36.5"]
        )
        let reading = try await service.fetchReading(near: bedok)

        #expect(reading.psi == 250)
        #expect(reading.airTemperatureCelsius == 36.5)
        #expect(RiskClassifier.assess(reading).overall == .high)
    }

    @Test func missingArgumentDefaultsToNoRain() async throws {
        let service = FixedHazardDataService.fromLaunchArguments(["-uitesting"])
        let reading = try await service.fetchReading(near: bedok)

        #expect(reading.rainfallMillimetres == 0)
        #expect(RiskClassifier.classify(reading) == .low)
    }

    @Test func unparseableArgumentDefaultsToNoRain() async throws {
        let service = FixedHazardDataService.fromLaunchArguments(["-simulateRainfall", "heavy"])
        let reading = try await service.fetchReading(near: bedok)

        #expect(reading.rainfallMillimetres == 0)
    }

    @Test func simulateHazardFailureArgumentProducesAFailure() async throws {
        let service = FixedHazardDataService.fromLaunchArguments(["-uitesting", "-simulateHazardFailure"])
        await #expect(throws: HazardDataError.requestFailed) {
            try await service.fetchReading(near: bedok)
        }
    }

    @Test func hazardFailureWinsOverASimulatedRainfallValue() async throws {
        let service = FixedHazardDataService.fromLaunchArguments(
            ["-simulateRainfall", "6.0", "-simulateHazardFailure"]
        )
        await #expect(throws: HazardDataError.requestFailed) {
            try await service.fetchReading(near: bedok)
        }
    }

    @Test func argumentAtEndOfListDefaultsToNoRain() async throws {
        let service = FixedHazardDataService.fromLaunchArguments(["-simulateRainfall"])
        let reading = try await service.fetchReading(near: bedok)

        #expect(reading.rainfallMillimetres == 0)
    }
}
