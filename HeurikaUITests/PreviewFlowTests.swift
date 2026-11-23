import XCTest

/// A real app walkthrough for a captured iPhone simulator preview.
final class PreviewFlowTests: XCTestCase {
    func testKeyboardUse() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 15))
        for _ in 0..<3 { app.buttons["Continue"].tap() }
        app.buttons["Set Up Keyboard"].tap()

        let consentSwitch = app.switches.firstMatch
        XCTAssertTrue(consentSwitch.waitForExistence(timeout: 5))
        consentSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        XCTAssertEqual(consentSwitch.value as? String, "1")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.buttons["Open Settings"].waitForExistence(timeout: 5))
        app.buttons["Open Settings"].tap()
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 10))
        if settings.buttons["Keyboards"].firstMatch.exists {
            settings.buttons["Keyboards"].firstMatch.tap()
        } else {
            let general = settings.buttons["General"].firstMatch
            XCTAssertTrue(general.waitForExistence(timeout: 10), settings.debugDescription)
            general.tap()
            let keyboard = settings.buttons["Keyboard"].firstMatch
            XCTAssertTrue(keyboard.waitForExistence(timeout: 10), settings.debugDescription)
            keyboard.tap()
            let keyboards = settings.buttons["Keyboards"].firstMatch
            XCTAssertTrue(keyboards.waitForExistence(timeout: 10), settings.debugDescription)
            keyboards.tap()
        }
        print("KEYBOARDS SETTINGS: \(settings.debugDescription)")
    }

    func testPreviewFlow() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 15))
        pause(2)

        for _ in 0..<3 {
            app.buttons["Continue"].tap()
            pause(2)
        }

        app.buttons["Set Up Keyboard"].tap()
        pause(2)
        let consentSwitch = app.switches.firstMatch
        XCTAssertTrue(consentSwitch.waitForExistence(timeout: 5))
        consentSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        XCTAssertEqual(consentSwitch.value as? String, "1")
        let consentContinue = app.buttons["Continue"]
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: consentContinue
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 8), .completed)
        consentContinue.tap()
        pause(2)
        app.buttons["I'll do this later"].tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        pause(3)
        let scratchpad = app.descendants(matching: .any)["previewScratchpad"]
        XCTAssertTrue(scratchpad.waitForExistence(timeout: 5))
        scratchpad.tap()
        scratchpad.typeText("Can you send the slides by friday?")
        pause(3)
        app.swipeUp()
        pause(2)
        app.tabBars.buttons["Deeds"].tap()
        pause(3)
        app.tabBars.buttons["Settings"].tap()
        pause(3)
        app.tabBars.buttons["Home"].tap()
        pause(3)
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
