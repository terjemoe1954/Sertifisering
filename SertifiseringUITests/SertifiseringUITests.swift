//
//  SertifiseringUITests.swift
//  SertifiseringUITests
//
//  Created by Terje Moe on 03/09/2026.
//

import XCTest

final class SertifiseringUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesToInspectionList() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["Sertifisering"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCustomerOverviewCanOpenFromMainList() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["Sertifisering"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["UI Testkunde AS, Testhall, 1 maskiner, Ferdig fra tekniker, Godkjent med mangel, 1 mangler"].waitForExistence(timeout: 5))

        app.buttons["Kunder"].tap()

        XCTAssertTrue(app.navigationBars["Kunder"].waitForExistence(timeout: 5))
        let customerButton = app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", "UI Testkunde AS, 1 kontroller, 1 maskiner, 1 klar")).firstMatch
        XCTAssertTrue(customerButton.waitForExistence(timeout: 5))
        customerButton.tap()

        XCTAssertTrue(app.navigationBars["UI Testkunde AS"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["UI Traverskran, Kran / UI-KR-1, 1 kontroller, Ferdig fra tekniker"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSeededInspectionDetailShowsChecksAndExports() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["Sertifisering"].waitForExistence(timeout: 5))
        let seededInspectionButton = app.buttons["UI Testkunde AS, Testhall, 1 maskiner, Ferdig fra tekniker, Godkjent med mangel, 1 mangler"]
        XCTAssertTrue(seededInspectionButton.waitForExistence(timeout: 5))
        seededInspectionButton.tap()

        XCTAssertTrue(app.navigationBars["UI Testkunde AS"].waitForExistence(timeout: 5))

        for _ in 0..<5 where !app.staticTexts["Teknikersjekk"].exists {
            app.swipeUp()
        }

        XCTAssertTrue(app.staticTexts["Teknikersjekk"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Firma/eier"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Kontrollør"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Minst én maskin"].waitForExistence(timeout: 5))

        for _ in 0..<5 where !app.buttons["Generer PDF"].exists {
            app.swipeUp()
        }

        XCTAssertTrue(app.buttons["Generer PDF"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Lag sertifikatgrunnlag"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHelpGuideCanOpenFromSettings() throws {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["Sertifisering"].waitForExistence(timeout: 5))
        app.buttons["Innstillinger"].tap()
        XCTAssertTrue(app.navigationBars["Innstillinger"].waitForExistence(timeout: 5))

        let helpGuideButton = app.buttons["Åpne brukerveiledning"]
        for _ in 0..<5 where !helpGuideButton.exists {
            app.swipeUp()
        }

        XCTAssertTrue(helpGuideButton.waitForExistence(timeout: 5))
        helpGuideButton.tap()
        XCTAssertTrue(app.navigationBars["Brukerveiledning"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Lukk"].waitForExistence(timeout: 5))
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }
}
