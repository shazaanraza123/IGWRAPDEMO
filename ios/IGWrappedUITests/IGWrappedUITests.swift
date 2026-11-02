import XCTest

final class IGWrappedUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testMayaClaimSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-session"]
        app.launch()
        let maya = app.buttons["persona-maya"]
        XCTAssertTrue(maya.waitForExistence(timeout: 10))
        maya.tap()
        let ready = app.staticTexts["wrapped-ready"]
        XCTAssertTrue(ready.waitForExistence(timeout: 40))

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(ready.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["persona-maya"].exists)
    }
}
