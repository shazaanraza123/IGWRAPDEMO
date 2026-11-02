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

    func testFriendStoryOpensAndCloses() {
        let app = XCUIApplication()
        app.launch()
        let friend = app.buttons["story-jules.mp"]
        XCTAssertTrue(friend.waitForExistence(timeout: 10))
        friend.tap()
        let close = app.buttons["story-close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["story-viewer"].exists || app.images["story-viewer"].exists)
        close.tap()
        XCTAssertTrue(app.buttons["tab-home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["story-close"].exists)

        app.buttons["story-dee.films"].tap()
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        top.press(forDuration: 0.05, thenDragTo: bottom)
        XCTAssertTrue(app.buttons["tab-home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["story-close"].exists)
    }
}
