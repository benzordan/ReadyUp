//
//  HazardGeographyTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct HazardGeographyTests {

    // Real coordinates from NEA's live area_metadata.
    private let bedok = GeoPoint(latitude: 1.321, longitude: 103.924)
    private let angMoKio = GeoPoint(latitude: 1.375, longitude: 103.839)
    private let jurongWest = GeoPoint(latitude: 1.352, longitude: 103.697)
    private let cupertino = GeoPoint(latitude: 37.3349, longitude: -122.0090)

    // MARK: - Distance

    @Test func distanceToSelfIsZero() {
        #expect(HazardGeography.distanceMetres(from: bedok, to: bedok) < 0.0001)
    }

    @Test func distanceBetweenBedokAndAngMoKioIsAboutTenKilometres() {
        let distance = HazardGeography.distanceMetres(from: bedok, to: angMoKio)
        #expect(abs(distance - 11_200) < 500, "got \(distance)m")
    }

    @Test func distanceIsSymmetric() {
        let there = HazardGeography.distanceMetres(from: bedok, to: jurongWest)
        let back = HazardGeography.distanceMetres(from: jurongWest, to: bedok)
        #expect(abs(there - back) < 0.0001)
    }

    // MARK: - Nearest

    @Test func nearestPicksTheClosestOfSeveral() {
        let areas = [angMoKio, jurongWest, bedok]
        let nearest = HazardGeography.nearest(to: bedok, among: areas) { $0 }

        #expect(nearest?.item == bedok)
        #expect((nearest?.distanceMetres ?? 1) < 0.0001)
    }

    @Test func nearestReturnsNilForEmptyList() {
        let nearest = HazardGeography.nearest(to: bedok, among: [GeoPoint]()) { $0 }
        #expect(nearest == nil)
    }

    @Test func nearestReturnsTheOnlyItemInASingletonList() {
        let nearest = HazardGeography.nearest(to: bedok, among: [angMoKio]) { $0 }
        #expect(nearest?.item == angMoKio)
    }

    @Test func nearestReportsTheDistanceToTheChosenItem() {
        let nearest = HazardGeography.nearest(to: bedok, among: [angMoKio, jurongWest]) { $0 }
        let expected = HazardGeography.distanceMetres(from: bedok, to: angMoKio)
        #expect(nearest?.item == angMoKio)
        #expect(abs((nearest?.distanceMetres ?? 0) - expected) < 0.0001)
    }

    @Test func nearestWorksThroughACoordinateExtractingClosure() {
        struct Station { let name: String; let point: GeoPoint }
        let stations = [Station(name: "Far", point: jurongWest), Station(name: "Near", point: bedok)]

        let nearest = HazardGeography.nearest(to: bedok, among: stations, location: \.point)
        #expect(nearest?.item.name == "Near")
    }

    // MARK: - Coverage

    @Test func singaporeAreasAreWithinCoverage() {
        for area in [bedok, angMoKio, jurongWest] {
            let distance = HazardGeography.distanceMetres(from: bedok, to: area)
            #expect(distance <= HazardGeography.maxCoverageDistanceMetres)
        }
    }

    // The simulator defaults to Cupertino, so without this guard the app would
    // confidently name a rainfall station on another continent.
    @Test func cupertinoIsOutsideCoverage() {
        let distance = HazardGeography.distanceMetres(from: cupertino, to: bedok)
        #expect(distance > HazardGeography.maxCoverageDistanceMetres)
        #expect(distance > 10_000_000, "expected an intercontinental distance, got \(distance)m")
    }
}
