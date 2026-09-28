//
//  PrepareTabUITests.swift
//  ReadyUpUITests
//

import XCTest

final class PrepareTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uitesting"] + extraArguments
        app.launch()
        return app
    }

    private func launchPrepare(extraArguments: [String] = []) -> XCUIApplication {
        let app = launchApp(extraArguments: extraArguments)
        app.buttons["Prepare"].tap()
        return app
    }

    func testAllFourTabsExist() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Prepare"].exists)
        XCTAssertTrue(app.buttons["Alerts"].exists)
        XCTAssertTrue(app.buttons["Resource Hub"].exists)
    }

    func testPrepareTabShowsScoreDrillAndHazardAreas() throws {
        let app = launchPrepare()

        XCTAssertTrue(app.staticTexts["Starter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["drill.start"].exists)
        XCTAssertTrue(app.staticTexts["Hazard areas"].exists)
        XCTAssertTrue(app.staticTexts["Fire"].exists)
        XCTAssertTrue(app.staticTexts["First Aid"].exists)
    }

    func testBrowseAllMissionsListsSeededMissions() throws {
        let app = launchPrepare()

        app.buttons["Browse all missions"].tap()

        XCTAssertTrue(app.staticTexts["Assemble your Ready Bag"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["complete.task.ready_bag"].exists)
    }

    // Targets the mission by accessibility identifier rather than list position,
    // so regrouping the Prepare tab can never silently retarget this test.
    func testCompletingTaskAwardsThirtyPoints() throws {
        let app = launchPrepare()

        XCTAssertTrue(app.staticTexts["0 pts"].waitForExistence(timeout: 5))
        app.buttons["Browse all missions"].tap()

        let completeButton = app.buttons["complete.task.ready_bag"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5))
        completeButton.tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["30 pts"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["70 pts to Prepared"].exists)
    }

    func testCorrectQuizAnswerAwardsTenPoints() throws {
        let app = launchPrepare()

        XCTAssertTrue(app.staticTexts["0 pts"].waitForExistence(timeout: 5))
        app.buttons["Browse all missions"].tap()

        let quizButton = app.buttons["quiz.quiz.emergency_number.start"]
        XCTAssertTrue(quizButton.waitForExistence(timeout: 5))
        quizButton.tap()

        XCTAssertTrue(app.buttons["995"].waitForExistence(timeout: 5))
        app.buttons["995"].tap()
        app.buttons["Submit"].tap()

        XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["10 pts"].waitForExistence(timeout: 5))
    }

    func testWrongQuizAnswerAwardsNothing() throws {
        let app = launchPrepare()

        XCTAssertTrue(app.staticTexts["0 pts"].waitForExistence(timeout: 5))
        app.buttons["Browse all missions"].tap()

        let quizButton = app.buttons["quiz.quiz.emergency_number.start"]
        XCTAssertTrue(quizButton.waitForExistence(timeout: 5))
        quizButton.tap()

        XCTAssertTrue(app.buttons["999"].waitForExistence(timeout: 5))
        app.buttons["999"].tap()
        app.buttons["Submit"].tap()

        XCTAssertTrue(app.staticTexts.containing(
            NSPredicate(format: "label BEGINSWITH 'Not quite'")
        ).firstMatch.waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["0 pts"].waitForExistence(timeout: 5))
    }

    // MARK: - Flow 1: drills

    func testDrillPresentsThreeStepsAndCanBeClosed() throws {
        let app = launchPrepare()

        let start = app.buttons["drill.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        XCTAssertTrue(app.buttons["drill.start"].waitForExistence(timeout: 5))
    }

    func testSkippingThroughDrillReachesSummary() throws {
        let app = launchPrepare()

        app.buttons["drill.start"].tap()
        XCTAssertTrue(app.staticTexts["Step 1 of 3"].waitForExistence(timeout: 5))

        // Each step is either a task (Skip) or a quiz (Submit then Next).
        for _ in 0..<3 {
            if app.buttons["drill.skip"].exists {
                app.buttons["drill.skip"].tap()
            } else if app.buttons["Submit"].exists {
                app.buttons.element(boundBy: 1).tap()
                app.buttons["Submit"].tap()
                app.buttons["Next"].tap()
            }
        }

        XCTAssertTrue(app.staticTexts["Drill complete"].waitForExistence(timeout: 5))
        app.buttons["drill.done"].tap()
        XCTAssertTrue(app.buttons["drill.start"].waitForExistence(timeout: 5))
    }

    // MARK: - Flow 3: hazard areas

    func testHazardAreaTileOpensDomainScreen() throws {
        let app = launchPrepare()

        XCTAssertTrue(app.staticTexts["Fire"].waitForExistence(timeout: 5))
        app.staticTexts["Fire"].tap()

        XCTAssertTrue(app.staticTexts["Complete the home fire safety checklist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["complete.task.lpg_check"].exists)
    }

    func testDomainScreenLinksIntoResourceHub() throws {
        let app = launchPrepare()

        app.staticTexts["Fire"].tap()
        XCTAssertTrue(app.buttons["Read the guides"].waitForExistence(timeout: 5))
        app.buttons["Read the guides"].tap()

        XCTAssertTrue(app.staticTexts["Using a Fire Extinguisher: P.A.S.S."].waitForExistence(timeout: 5))
    }

    // MARK: - Decay

    // -seedStaleProgress backdates completions so stale states are visible
    // without waiting months.
    func testStaleMissionShowsNeedsRefresh() throws {
        let app = launchPrepare(extraArguments: ["-seedStaleProgress"])

        XCTAssertTrue(app.buttons["drill.start"].waitForExistence(timeout: 5))
        app.buttons["Browse all missions"].tap()

        XCTAssertTrue(app.staticTexts["Needs refresh"].waitForExistence(timeout: 5))
        // An expired task offers Refresh rather than Mark Done.
        XCTAssertTrue(app.buttons["complete.task.ready_bag"].exists)
        XCTAssertEqual(app.buttons["complete.task.ready_bag"].label, "Refresh")
    }

    func testStaleMissionsAreSurfacedInTheScoreHeader() throws {
        let app = launchPrepare(extraArguments: ["-seedStaleProgress"])

        let header = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS 'need refreshing' OR label CONTAINS 'needs refreshing'")
        ).firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5))
    }
}
