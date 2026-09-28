//
//  AlertsTabUITests.swift
//  ReadyUpUITests
//

import XCTest

// -uitesting swaps in canned location and hazard services, so these never touch
// the live NEA API or trigger a real permission prompt.
final class AlertsTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchAlerts(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uitesting"] + extraArguments
        app.launch()
        app.buttons["Alerts"].tap()
        return app
    }

    func testRestingStateShowsZoneRiskAndRainfall() throws {
        let app = launchAlerts()

        XCTAssertTrue(app.staticTexts["Bedok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Singapore"].exists)
        XCTAssertTrue(app.staticTexts["mm"].exists)
        XCTAssertTrue(app.staticTexts["All clear."].exists)
        XCTAssertTrue(app.staticTexts["No action required."].exists)
    }

    func testNoRainShowsLowTier() throws {
        let app = launchAlerts(extraArguments: ["-simulateRainfall", "0.0"])

        XCTAssertTrue(app.staticTexts["0.0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["All clear."].exists)
    }

    func testModerateRainfallShowsModerateGuidance() throws {
        let app = launchAlerts(extraArguments: ["-simulateRainfall", "1.0"])

        XCTAssertTrue(app.staticTexts["Heavy rain developing."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Stay indoors and monitor, avoid low-lying areas."].exists)
    }

    func testHighRainfallShowsFloodGuidance() throws {
        // A live High reading fires the takeover on launch; the resting-state
        // guidance is what remains after the user acknowledges it.
        let app = XCUIApplication()
        app.launchArguments += ["-uitesting", "-simulateRainfall", "6.0"]
        app.launch()

        XCTAssertTrue(app.buttons["alert.acknowledge"].waitForExistence(timeout: 10))
        app.buttons["alert.acknowledge"].tap()
        app.buttons["Alerts"].tap()

        XCTAssertTrue(app.staticTexts["Flash flood risk."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Move to higher ground now, avoid underpasses and canals."].exists)
        XCTAssertTrue(app.staticTexts["6.0"].exists)
    }

    func testRainfallCardShowsTheStationItCameFrom() throws {
        let app = launchAlerts()

        let attribution = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS 'Bedok Reservoir'")
        ).firstMatch
        XCTAssertTrue(attribution.waitForExistence(timeout: 5))
    }

    func testPullToRefreshKeepsTheReadingVisible() throws {
        let app = launchAlerts()

        XCTAssertTrue(app.staticTexts["Bedok"].waitForExistence(timeout: 5))
        app.scrollViews.firstMatch.swipeDown()

        XCTAssertTrue(app.staticTexts["Bedok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["All clear."].exists)
    }
}
