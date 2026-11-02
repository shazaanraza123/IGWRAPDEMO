import XCTest

final class IGWrappedUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testPlaceholderTabKeepsTheBar() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["tab-reels"].tap()
        XCTAssertTrue(app.staticTexts["Reels"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-home"].exists)
    }

    func testMayaClaimSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-session"]
        app.launch()
        let wrapped = app.buttons["wrapped-bubble"]
        XCTAssertTrue(wrapped.waitForExistence(timeout: 10))
        wrapped.tap()
        let maya = app.buttons["persona-maya"]
        XCTAssertTrue(maya.waitForExistence(timeout: 10))
        maya.tap()
        let ready = app.staticTexts["wrapped-ready"]
        XCTAssertTrue(ready.waitForExistence(timeout: 40))

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.buttons["tab-home"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["persona-maya"].exists)
        app.buttons["wrapped-bubble"].tap()
        XCTAssertTrue(ready.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["persona-maya"].exists)
    }
}
