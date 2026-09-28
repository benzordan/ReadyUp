//
//  ResourceHubTabUITests.swift
//  ReadyUpUITests
//

import XCTest

final class ResourceHubTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchResourceHub() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uitesting"]
        app.launch()
        app.buttons["Resource Hub"].tap()
        return app
    }

    func testGridShowsAllCategories() throws {
        let app = launchResourceHub()

        XCTAssertTrue(app.staticTexts["Household Readiness"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Fire Safety"].exists)
        XCTAssertTrue(app.staticTexts["First Aid & Medical"].exists)
        XCTAssertTrue(app.staticTexts["Shelter & Warnings"].exists)
        XCTAssertTrue(app.staticTexts["Emergency Contacts"].exists)
    }

    func testTappingCategoryShowsRealArticles() throws {
        let app = launchResourceHub()

        XCTAssertTrue(app.staticTexts["Fire Safety"].waitForExistence(timeout: 5))
        app.staticTexts["Fire Safety"].tap()

        XCTAssertTrue(app.staticTexts["Using a Fire Extinguisher: P.A.S.S."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The Five-Point LPG Safety Check"].exists)
    }

    func testArticleDetailShowsStepsAndCitation() throws {
        let app = launchResourceHub()

        XCTAssertTrue(app.staticTexts["Fire Safety"].waitForExistence(timeout: 5))
        app.staticTexts["Fire Safety"].tap()

        let article = app.staticTexts["Using a Fire Extinguisher: P.A.S.S."]
        XCTAssertTrue(article.waitForExistence(timeout: 5))
        article.tap()

        XCTAssertTrue(app.staticTexts["Pull the safety pin out of the handle."].waitForExistence(timeout: 5))

        let citation = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS 'SCDF Civil Defence Emergency Handbook'")
        ).firstMatch
        XCTAssertTrue(citation.exists, "Article detail should show its source citation")
    }

    func testEmergencyContactsShowCallAndTextActions() throws {
        let app = launchResourceHub()

        XCTAssertTrue(app.staticTexts["Emergency Contacts"].waitForExistence(timeout: 5))
        app.staticTexts["Emergency Contacts"].tap()

        XCTAssertTrue(app.staticTexts["995"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Fire & Ambulance"].exists)
        XCTAssertGreaterThan(app.buttons.matching(identifier: "Call Fire & Ambulance").count, 0)

        // The Deaf/Hard-of-Hearing SMS lines must offer Text, never Call.
        XCTAssertGreaterThan(
            app.buttons.matching(identifier: "Text SMS Emergency (Fire & Ambulance)").count, 0
        )
        XCTAssertEqual(
            app.buttons.matching(identifier: "Call SMS Emergency (Fire & Ambulance)").count, 0
        )
    }
}
