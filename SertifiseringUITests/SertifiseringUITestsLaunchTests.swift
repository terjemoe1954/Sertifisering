//
//  SertifiseringUITestsLaunchTests.swift
//  SertifiseringUITests
//
//  Created by Terje Moe on 03/09/2026.
//

import XCTest

final class SertifiseringUITestsLaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
