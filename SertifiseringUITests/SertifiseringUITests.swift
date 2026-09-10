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
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Sertifisering"].waitForExistence(timeout: 5))
    }
}
