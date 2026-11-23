import XCTest

/// A real app walkthrough for a captured iPhone simulator preview.
final class PreviewFlowTests: XCTestCase {
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
        app.switches.firstMatch.tap()
        app.buttons["Continue"].tap()
        pause(2)
        app.buttons["I'll do this later"].tap()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        pause(3)
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
