//
//  HazardReading.swift
//  ReadyUp
//

import Foundation

// A coordinate, deliberately not CLLocationCoordinate2D or CLLocation.
//
// Being Equatable keeps tests readable, being Sendable lets it cross the
// nonisolated CoreLocation delegate hop safely (a CLLocation could not), and
// using our own type keeps CoreLocation out of Models, ViewModels and Views.
struct GeoPoint: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    // The area the report's prototype displays, taken from NEA's own
    // area_metadata. Used by previews and the UI-test fake.
    static let bedok = GeoPoint(latitude: 1.321, longitude: 103.924)
}

// One resolved hazard picture for the user's location: what the nearest station
// is measuring, which NEA area they are in, and what the next two hours hold.
struct HazardReading: Equatable {
    let zoneName: String
    let stationName: String
    let stationDistanceMetres: Double
    // NEA's TB1 five-minute rainfall total, in millimetres.
    let rainfallMillimetres: Double
    // The 24-hour PSI for the user's region and the air temperature at the
    // nearest station. nil when the secondary feed was unavailable — flood
    // alerting must never fail because a haze or temperature fetch did.
    let psi: Int?
    let airTemperatureCelsius: Double?
    let forecast: String
    // NEA's own reading timestamp, not the time we fetched it.
    let observedAt: Date
}

enum HazardGeography {

    private static let earthRadiusMetres: Double = 6_371_000

    // Singapore spans roughly 50km east to west. A nearest station further away
    // than this means the user is not in the coverage area at all, which is the
    // difference between saying so and confidently naming a station on another
    // continent.
    static let maxCoverageDistanceMetres: Double = 50_000

    // ========================================
    // static func distanceMetres(from origin: GeoPoint, to destination: GeoPoint) -> Double
    // Great-circle distance by the haversine formula. Pure function, unit-tested against real NEA area coordinates.
    // Returns: The distance in metres.
    // ========================================
    static func distanceMetres(from origin: GeoPoint, to destination: GeoPoint) -> Double {
        let latitudeDelta = (destination.latitude - origin.latitude) * .pi / 180
        let longitudeDelta = (destination.longitude - origin.longitude) * .pi / 180
        let originLatitude = origin.latitude * .pi / 180
        let destinationLatitude = destination.latitude * .pi / 180

        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
            * cos(originLatitude) * cos(destinationLatitude)

        return 2 * earthRadiusMetres * atan2(sqrt(a), sqrt(1 - a))
    }

    // ========================================
    // static func nearest<Item>(to point: GeoPoint, among items: [Item], location: (Item) -> GeoPoint) -> (item: Item, distanceMetres: Double)?
    // Finds the closest item to a point. Generic over a coordinate-extracting closure because both rainfall stations and forecast areas need it and their nested coordinate shapes differ. Pure function, unit-tested.
    // Returns: The nearest item with its distance, or nil when the list is empty.
    // ========================================
    static func nearest<Item>(
        to point: GeoPoint,
        among items: [Item],
        location: (Item) -> GeoPoint
    ) -> (item: Item, distanceMetres: Double)? {
        items.reduce(nil) { closest, item in
            let distance = distanceMetres(from: point, to: location(item))
            guard let closest else { return (item, distance) }
            return distance < closest.distanceMetres ? (item, distance) : closest
        }
    }
}
