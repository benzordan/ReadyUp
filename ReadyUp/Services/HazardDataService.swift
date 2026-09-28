//
//  HazardDataService.swift
//  ReadyUp
//

import Foundation

enum HazardDataError: Error, Equatable {
    case requestFailed
    case decodingFailed
    case noData
    case outsideCoverage
}

protocol HazardDataServicing {
    func fetchReading(near point: GeoPoint) async throws -> HazardReading
}

// Reads Singapore's live hazard data from NEA's open-data platform.
//
// Four feeds are combined. The five-minute rainfall totals are the primary
// hazard signal, and the two-hour forecast's area_metadata supplies the 47
// named NEA areas used as the app's zone model — those two are required. The
// 24-hour PSI (haze) and air temperature (heat) are secondary: a failure there
// yields nil fields, never a failed reading, because flood alerting must not
// depend on feeds it doesn't need.
//
// The decode step is deliberately a separate pure function so it can be tested
// against real payloads without a network.
final class NEAHazardDataService: HazardDataServicing {

    static let rainfallURL = URL(string: "https://api-open.data.gov.sg/v2/real-time/api/rainfall")!
    static let twoHourForecastURL = URL(string: "https://api-open.data.gov.sg/v2/real-time/api/two-hr-forecast")!
    static let psiURL = URL(string: "https://api-open.data.gov.sg/v2/real-time/api/psi")!
    static let airTemperatureURL = URL(string: "https://api-open.data.gov.sg/v2/real-time/api/air-temperature")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // ========================================
    // func fetchReading(near point: GeoPoint) async throws -> HazardReading
    // Fetches all four NEA feeds concurrently and resolves them into one reading for the given coordinate. Only the rainfall and forecast feeds can fail the fetch; PSI and temperature failures degrade to nil fields.
    // Returns: The hazard reading, or throws a HazardDataError for a failed request, bad payload, missing data, or a location outside Singapore.
    // ========================================
    func fetchReading(near point: GeoPoint) async throws -> HazardReading {
        async let rainfall = fetch(Self.rainfallURL)
        async let forecast = fetch(Self.twoHourForecastURL)
        async let psi = fetch(Self.psiURL)
        async let airTemperature = fetch(Self.airTemperatureURL)

        return try Self.makeReading(
            rainfallData: await rainfall,
            forecastData: await forecast,
            psiData: try? await psi,
            airTemperatureData: try? await airTemperature,
            near: point
        )
    }

    // ========================================
    // private func fetch(_ url: URL) async throws -> Data
    // Performs one GET, mapping any transport or non-200 response to a HazardDataError so callers never see a raw URLError.
    // Returns: The response body, or throws HazardDataError.requestFailed.
    // ========================================
    private func fetch(_ url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw HazardDataError.requestFailed
            }
            return data
        } catch let error as HazardDataError {
            throw error
        } catch {
            throw HazardDataError.requestFailed
        }
    }

    // ========================================
    // nonisolated static func makeReading(rainfallData: Data, forecastData: Data, psiData: Data?, airTemperatureData: Data?, near point: GeoPoint) throws -> HazardReading
    // Decodes the NEA payloads and resolves the nearest station, area and region to the given point. Pure function with no networking, unit-tested against the real response shapes; refuses to fabricate a zero rainfall value when the nearest station is absent from the readings, since a fabricated zero reads as "all clear". Secondary payloads that are missing or malformed yield nil fields rather than errors.
    // Returns: The resolved reading, or throws a HazardDataError.
    // ========================================
    nonisolated static func makeReading(
        rainfallData: Data,
        forecastData: Data,
        psiData: Data? = nil,
        airTemperatureData: Data? = nil,
        near point: GeoPoint
    ) throws -> HazardReading {
        let decoder = makeDecoder()

        let rainfall: StationReadingResponse
        let forecast: TwoHourForecastResponse
        do {
            rainfall = try decoder.decode(StationReadingResponse.self, from: rainfallData)
            forecast = try decoder.decode(TwoHourForecastResponse.self, from: forecastData)
        } catch {
            throw HazardDataError.decodingFailed
        }

        // Both endpoints answer 200 with a non-zero code on an API-level error.
        guard rainfall.code == 0, forecast.code == 0 else { throw HazardDataError.requestFailed }

        guard let latest = rainfall.data.readings.first else { throw HazardDataError.noData }

        guard let nearestStation = HazardGeography.nearest(
            to: point,
            among: rainfall.data.stations,
            location: { GeoPoint(latitude: $0.location.latitude, longitude: $0.location.longitude) }
        ) else { throw HazardDataError.noData }

        guard nearestStation.distanceMetres <= HazardGeography.maxCoverageDistanceMetres else {
            throw HazardDataError.outsideCoverage
        }

        guard let millimetres = latest.data.first(where: { $0.stationId == nearestStation.item.id })?.value else {
            throw HazardDataError.noData
        }

        guard let nearestArea = HazardGeography.nearest(
            to: point,
            among: forecast.data.areaMetadata,
            location: { GeoPoint(latitude: $0.labelLocation.latitude, longitude: $0.labelLocation.longitude) }
        ) else { throw HazardDataError.noData }

        // An unmatched area leaves the forecast empty, which is safe: the
        // rainfall reading still drives the tier and the view hides the row.
        let forecastText = forecast.data.items.first?
            .forecasts.first { $0.area == nearestArea.item.name }?
            .forecast ?? ""

        return HazardReading(
            zoneName: nearestArea.item.name,
            stationName: nearestStation.item.name,
            stationDistanceMetres: nearestStation.distanceMetres,
            rainfallMillimetres: millimetres,
            psi: psiData.flatMap { psiValue(from: $0, near: point, decoder: decoder) },
            airTemperatureCelsius: airTemperatureData.flatMap { airTemperature(from: $0, near: point, decoder: decoder) },
            forecast: forecastText,
            observedAt: latest.timestamp
        )
    }

    // ========================================
    // private nonisolated static func psiValue(from data: Data, near point: GeoPoint, decoder: JSONDecoder) -> Int?
    // Picks the 24-hour PSI for the region nearest the point. Returns nil on any failure — haze is a secondary signal, and a broken haze payload must never break flood alerting.
    // Returns: The regional PSI, or nil.
    // ========================================
    private nonisolated static func psiValue(from data: Data, near point: GeoPoint, decoder: JSONDecoder) -> Int? {
        guard let response = try? decoder.decode(PSIResponse.self, from: data),
              response.code == 0,
              let readings = response.data.items.first?.readings.psiTwentyFourHourly,
              let region = HazardGeography.nearest(
                  to: point,
                  among: response.data.regionMetadata,
                  location: { GeoPoint(latitude: $0.labelLocation.latitude, longitude: $0.labelLocation.longitude) }
              )?.item
        else { return nil }
        return readings[region.name]
    }

    // ========================================
    // private nonisolated static func airTemperature(from data: Data, near point: GeoPoint, decoder: JSONDecoder) -> Double?
    // Picks the air temperature at the station nearest the point. The feed shares the rainfall feed's shape, so it reuses the same response type. Returns nil on any failure, like psiValue.
    // Returns: Degrees Celsius, or nil.
    // ========================================
    private nonisolated static func airTemperature(from data: Data, near point: GeoPoint, decoder: JSONDecoder) -> Double? {
        guard let response = try? decoder.decode(StationReadingResponse.self, from: data),
              response.code == 0,
              let latest = response.data.readings.first,
              let station = HazardGeography.nearest(
                  to: point,
                  among: response.data.stations,
                  location: { GeoPoint(latitude: $0.location.latitude, longitude: $0.location.longitude) }
              )?.item
        else { return nil }
        return latest.data.first { $0.stationId == station.id }?.value
    }

    // ========================================
    // private nonisolated static func makeDecoder() -> JSONDecoder
    // Builds the shared decoding strategy. convertFromSnakeCase covers the forecast feed's snake_case keys while leaving the rainfall feed's camelCase untouched, so one decoder serves both; iso8601 parses NEA's +08:00 timestamps.
    // Returns: A configured JSONDecoder.
    // ========================================
    private nonisolated static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

// MARK: - Response shapes

// Only the fields actually used are modelled; Decodable ignores the rest.
// The rainfall and air-temperature feeds share this stations-plus-readings
// shape, so one response type decodes both.
private struct StationReadingResponse: Decodable {
    struct Payload: Decodable {
        struct Station: Decodable {
            struct Location: Decodable {
                let latitude: Double
                let longitude: Double
            }
            let id: String
            let name: String
            let location: Location
        }

        struct ReadingBlock: Decodable {
            struct Entry: Decodable {
                let stationId: String
                let value: Double
            }
            let timestamp: Date
            let data: [Entry]
        }

        let stations: [Station]
        let readings: [ReadingBlock]
    }

    let code: Int
    let data: Payload
}

// The PSI feed keys its readings dictionary by band name in snake_case
// (psi_twenty_four_hourly), which the shared convertFromSnakeCase strategy
// turns into psiTwentyFourHourly; the region names inside carry no underscores
// and pass through untouched. Pinned by a fixture test.
private struct PSIResponse: Decodable {
    struct Payload: Decodable {
        struct Region: Decodable {
            struct LabelLocation: Decodable {
                let latitude: Double
                let longitude: Double
            }
            let name: String
            let labelLocation: LabelLocation
        }

        struct Item: Decodable {
            struct Readings: Decodable {
                let psiTwentyFourHourly: [String: Int]
            }
            let readings: Readings
        }

        let regionMetadata: [Region]
        let items: [Item]
    }

    let code: Int
    let data: Payload
}

private struct TwoHourForecastResponse: Decodable {
    struct Payload: Decodable {
        struct Area: Decodable {
            struct LabelLocation: Decodable {
                let latitude: Double
                let longitude: Double
            }
            let name: String
            let labelLocation: LabelLocation
        }

        struct Item: Decodable {
            struct AreaForecast: Decodable {
                let area: String
                let forecast: String
            }
            let forecasts: [AreaForecast]
        }

        let areaMetadata: [Area]
        let items: [Item]
    }

    let code: Int
    let data: Payload
}

// MARK: - Test double

// Returns a canned reading so previews and UI tests never hit the network.
final class FixedHazardDataService: HazardDataServicing {
    var result: Result<HazardReading, HazardDataError>

    init(result: Result<HazardReading, HazardDataError> = .success(.previewLow)) {
        self.result = result
    }

    func fetchReading(near point: GeoPoint) async throws -> HazardReading {
        try result.get()
    }

    // ========================================
    // static func fromLaunchArguments(_ arguments: [String]) -> FixedHazardDataService
    // Builds a fake serving a canned Bedok reading at the values following -simulateRainfall, -simulatePSI and -simulateTemperature, or a network failure for -simulateHazardFailure, so a UI test can drive any hazard's tier or the error path without networking. Pure function of its input, unit-tested.
    // Returns: A service primed with the requested outcome, defaulting to calm conditions.
    // ========================================
    static func fromLaunchArguments(_ arguments: [String]) -> FixedHazardDataService {
        // Failure wins: a test asking for the error path means it, whatever
        // hazard values happen to be alongside.
        if arguments.contains("-simulateHazardFailure") {
            return FixedHazardDataService(result: .failure(.requestFailed))
        }
        let reading = HazardReading.preview(
            millimetres: value(named: "-simulateRainfall", in: arguments) ?? 0,
            psi: value(named: "-simulatePSI", in: arguments).map(Int.init) ?? 55,
            celsius: value(named: "-simulateTemperature", in: arguments) ?? 31
        )
        return FixedHazardDataService(result: .success(reading))
    }

    private static func value(named name: String, in arguments: [String]) -> Double? {
        guard let flagIndex = arguments.firstIndex(of: name) else { return nil }
        let valueIndex = arguments.index(after: flagIndex)
        guard valueIndex < arguments.endIndex else { return nil }
        return Double(arguments[valueIndex])
    }
}

extension HazardReading {
    // Fixed timestamp so previews and UI-test screenshots stay reproducible.
    private static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    // Calm secondary conditions by default (PSI 55 and 31°C both classify Low),
    // so existing rainfall-focused previews and tests are unaffected.
    static func preview(millimetres: Double, psi: Int? = 55, celsius: Double? = 31) -> HazardReading {
        HazardReading(
            zoneName: "Bedok",
            stationName: "Bedok Reservoir",
            stationDistanceMetres: 1_200,
            rainfallMillimetres: millimetres,
            psi: psi,
            airTemperatureCelsius: celsius,
            forecast: "Partly Cloudy (Day)",
            observedAt: referenceDate
        )
    }

    static let previewLow = preview(millimetres: 0)
    static let previewModerate = preview(millimetres: 1.5)
}
