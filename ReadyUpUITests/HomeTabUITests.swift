//
//  HomeTabUITests.swift
//  ReadyUpUITests
//

import XCTest

final class HomeTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // Home is the default tab, so nothing needs tapping to reach it.
    private func launchHome(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uitesting"] + extraArguments
        app.launch()
        return app
    }

    // MARK: - The three cards

    func testHomeShowsHazardPreparednessAndDrillCards() throws {
        let app = launchHome()

        XCTAssertTrue(app.staticTexts["Bedok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Singapore"].exists)
        XCTAssertTrue(app.staticTexts["mm"].exists)
        XCTAssertTrue(app.staticTexts["Starter"].exists)
        XCTAssertTrue(app.staticTexts["0 pts"].exists)
        XCTAssertTrue(app.buttons["home.drill.start"].exists)
    }

    func testHighRainfallShowsHighTierOnTheHazardCard() throws {
        let app = launchHome(extraArguments: ["-simulateRainfall", "6.0"])

        // A live High reading fires the takeover on launch; the card is what
        // the user sees after acknowledging it.
        XCTAssertTrue(app.buttons["alert.acknowledge"].waitForExistence(timeout: 10))
        app.buttons["alert.acknowledge"].tap()

        XCTAssertTrue(app.staticTexts["6.0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bedok"].exists)
    }

    // The dashboard must stay useful when hazard data is unavailable: a network
    // problem cannot be allowed to hide the score and the drill.
    func testHazardFailureStillShowsPreparednessAndDrill() throws {
        let app = launchHome(extraArguments: ["-simulateHazardFailure"])

        XCTAssertTrue(app.staticTexts["Starter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0 pts"].exists)
        XCTAssertTrue(app.buttons["home.drill.start"].exists)
        // The card reports the failure rather than showing nothing.
        XCTAssertTrue(app.staticTexts["Couldn't get the latest reading."].exists)
        XCTAssertTrue(app.buttons["Try Again"].exists)
    }

    // MARK: - Drill from Home

    // The staleness test: a drill started on Home must be reflected on Prepare,
    // which is only true because both screens share one view model.
    func testStartingADrillFromHomeShowsPointsOnPrepare() throws {
        let app = launchHome()

        // Drills are picked at random, so restart until one opens on a task
        // step. Quiz steps are avoided rather than answered: a correct answer
        // would add its own points and make the expected total depend on luck.
        var awarded = false
        for _ in 0..<10 {
            let start = app.buttons["home.drill.start"]
            XCTAssertTrue(start.waitForExistence(timeout: 5))
            start.tap()
            XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 5))

            if app.buttons["drill.complete"].exists {
                app.buttons["drill.complete"].tap()
                awarded = true
                break
            }
            app.buttons["Close"].tap()
        }
        XCTAssertTrue(awarded, "no drill opened on a task step in ten attempts")

        app.buttons["Close"].tap()
        app.buttons["Prepare"].tap()

        // A 30-point task from Starter leaves 70 to the Prepared tier. This line
        // only appears in the score header, unlike "30 pts", which mission rows
        // also show, so it proves the points genuinely arrived.
        XCTAssertTrue(app.staticTexts["70 pts to Prepared"].waitForExistence(timeout: 5))
    }

    // MARK: - Hazard flow

    func testJumpToHighShowsTakeoverAndAcknowledgeReturnsHome() throws {
        let app = launchHome()

        XCTAssertTrue(app.buttons["debug.panel"].waitForExistence(timeout: 5))
        app.buttons["debug.panel"].tap()

        let jump = app.buttons["debug.jumpHigh"]
        XCTAssertTrue(jump.waitForExistence(timeout: 5))
        jump.tap()

        XCTAssertTrue(app.staticTexts["FLASH FLOOD RISK HIGH"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Flash flood risk."].exists)
        XCTAssertTrue(app.staticTexts["Move to higher ground now, avoid underpasses and canals."].exists)

        let acknowledge = app.buttons["alert.acknowledge"]
        XCTAssertTrue(acknowledge.exists)
        acknowledge.tap()

        // The anti-trap assertion: the user is genuinely back on the dashboard.
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bedok"].exists)
    }

    func testTriggerEscalatesThroughToTheTakeover() throws {
        let app = launchHome()

        XCTAssertTrue(app.staticTexts["Low — All clear."].waitForExistence(timeout: 5))

        app.buttons["debug.panel"].tap()
        let trigger = app.buttons["debug.trigger"]
        XCTAssertTrue(trigger.waitForExistence(timeout: 5))
        trigger.tap()

        // The ramp takes ~5s; the intermediate Moderate frame is a 400ms window
        // and is deliberately not asserted.
        XCTAssertTrue(app.staticTexts["FLASH FLOOD RISK HIGH"].waitForExistence(timeout: 20))
    }

    // The live-data path end-to-end: no debug trigger involved — the reading
    // itself crossing High must produce the takeover, worded for its hazard.
    func testLiveHighHazeReadingShowsHazeTakeoverOnLaunch() throws {
        let app = launchHome(extraArguments: ["-simulatePSI", "250"])

        XCTAssertTrue(app.staticTexts["HAZE RISK HIGH"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Hazardous haze levels."].exists)

        app.buttons["alert.acknowledge"].tap()

        // Back on the dashboard, the pill reflects the live haze tier.
        XCTAssertTrue(app.staticTexts["Bedok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["High — Hazardous haze levels."].exists)
    }

    func testResetReturnsTheHazardCardToResting() throws {
        let app = launchHome()

        app.buttons["debug.panel"].tap()
        app.buttons["debug.jumpHigh"].tap()
        XCTAssertTrue(app.staticTexts["FLASH FLOOD RISK HIGH"].waitForExistence(timeout: 10))
        app.buttons["alert.acknowledge"].tap()

        app.buttons["debug.panel"].tap()
        let reset = app.buttons["debug.reset"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        reset.tap()

        XCTAssertTrue(app.staticTexts["Low — All clear."].waitForExistence(timeout: 5))
    }
}
