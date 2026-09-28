//
//  LocationService.swift
//  ReadyUp
//

import Foundation
import CoreLocation

enum LocationError: Error, Equatable {
    case authorizationDenied
    case authorizationRestricted
    case locationUnavailable
    case requestAlreadyInFlight
}

protocol LocationServicing {
    func requestCurrentLocation() async throws -> GeoPoint
}

// One-shot location lookup for resolving which NEA area the user is in.
//
// Region monitoring, which the report specifies for background alerting, is
// deliberately not here yet: it only earns its place once there is an alert
// engine for a boundary crossing to wake into.
final class CoreLocationService: NSObject, LocationServicing, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var pendingContinuation: CheckedContinuation<GeoPoint, Error>?

    override init() {
        super.init()
        manager.delegate = self
        // A 47-area zone lookup does not need best accuracy, and asking for
        // less returns faster and costs less battery.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // ========================================
    // func requestCurrentLocation() async throws -> GeoPoint
    // Requests authorization if needed, then a single location fix. Rejects overlapping calls rather than overwriting the stored continuation, which would strand the first caller awaiting forever.
    // Returns: The user's coordinate, or throws a LocationError for denial, restriction, or an unavailable fix.
    // ========================================
    func requestCurrentLocation() async throws -> GeoPoint {
        guard pendingContinuation == nil else { throw LocationError.requestAlreadyInFlight }

        return try await withCheckedThrowingContinuation { continuation in
            switch manager.authorizationStatus {
            case .denied:
                continuation.resume(throwing: LocationError.authorizationDenied)
            case .restricted:
                continuation.resume(throwing: LocationError.authorizationRestricted)
            case .notDetermined:
                pendingContinuation = continuation
                manager.requestWhenInUseAuthorization()
            default:
                pendingContinuation = continuation
                manager.requestLocation()
            }
        }
    }

    // ========================================
    // private func resume(with result: Result<GeoPoint, LocationError>)
    // The only place the pending continuation is ever resumed. Clears the stored reference before resuming, because CheckedContinuation traps on a second resume and CoreLocation can deliver both an authorization change and a location callback for one request.
    // Returns: Nothing.
    // ========================================
    private func resume(with result: Result<GeoPoint, LocationError>) {
        guard let continuation = pendingContinuation else { return }
        pendingContinuation = nil
        continuation.resume(with: result.mapError { $0 as Error })
    }

    // ========================================
    // private func handleAuthorizationChange(_ status: CLAuthorizationStatus)
    // Advances a waiting request once the user answers the permission prompt. Does nothing when no request is in flight, since this callback also fires once on delegate assignment.
    // Returns: Nothing.
    // ========================================
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        guard pendingContinuation != nil else { return }

        switch status {
        case .notDetermined:
            // The prompt is still on screen.
            return
        case .denied:
            resume(with: .failure(.authorizationDenied))
        case .restricted:
            resume(with: .failure(.authorizationRestricted))
        default:
            manager.requestLocation()
        }
    }

    // Delegate callbacks are nonisolated to satisfy the protocol under the
    // project's MainActor-by-default isolation. Each extracts plain Sendable
    // values before hopping, so no CLLocation ever crosses the boundary.

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let point = locations.last.map {
            GeoPoint(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        Task { @MainActor in
            resume(with: point.map { .success($0) } ?? .failure(.locationUnavailable))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let wasDenied = (error as? CLError)?.code == .denied
        Task { @MainActor in
            resume(with: .failure(wasDenied ? .authorizationDenied : .locationUnavailable))
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            handleAuthorizationChange(status)
        }
    }
}

// Returns a canned result so previews and UI tests never touch CoreLocation or
// trigger a real permission prompt.
final class FixedLocationService: LocationServicing {
    var result: Result<GeoPoint, LocationError>

    init(result: Result<GeoPoint, LocationError> = .success(.bedok)) {
        self.result = result
    }

    func requestCurrentLocation() async throws -> GeoPoint {
        try result.get()
    }
}
