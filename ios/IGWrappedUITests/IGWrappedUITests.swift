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

    func testPlayerTapZones() {
        let app = launchedPlayer()
        let player = app.otherElements["story-player"]
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)).tap()
        XCTAssertTrue(waitForLabel(player, "Card 2 of 13"))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
        XCTAssertTrue(waitForLabel(player, "Card 1 of 13"))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
        XCTAssertEqual(player.label, "Card 1 of 13")
    }

    func testPlayerHoldPausesAutoplay() {
        let app = launchedPlayer()
        let player = app.otherElements["story-player"]
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 8)
        XCTAssertEqual(player.label, "Card 1 of 13")
    }

    func testPlayerSwipeDownExits() {
        let app = launchedPlayer()
        let player = app.otherElements["story-player"]
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        top.press(forDuration: 0.05, thenDragTo: bottom)
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == 0"), object: player)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 3), .completed)
    }

    func testPlayerChapterSwipes() {
        let app = launchedPlayer()
        let player = app.otherElements["story-player"]
        drag(app, from: CGVector(dx: 0.9, dy: 0.22), to: CGVector(dx: 0.1, dy: 0.22))
        XCTAssertTrue(waitForLabel(player, "Card 3 of 13"))
        drag(app, from: CGVector(dx: 0.9, dy: 0.22), to: CGVector(dx: 0.1, dy: 0.22))
        XCTAssertTrue(waitForLabel(player, "Card 6 of 13"))
        drag(app, from: CGVector(dx: 0.1, dy: 0.22), to: CGVector(dx: 0.9, dy: 0.22))
        XCTAssertTrue(waitForLabel(player, "Card 3 of 13"))
    }

    func testPlayerSwipeUpOpensInfo() {
        let app = launchedPlayer()
        drag(app, from: CGVector(dx: 0.5, dy: 0.8), to: CGVector(dx: 0.5, dy: 0.2))
        XCTAssertTrue(app.otherElements["card-info"].waitForExistence(timeout: 3))
        app.buttons["card-info-close"].tap()
        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == 0"),
            object: app.otherElements["card-info"]
        )
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 3), .completed)
        XCTAssertEqual(app.otherElements["story-player"].label, "Card 1 of 13")
    }

    func testPlayerAutoplayAdvances() {
        let app = launchedPlayer()
        let player = app.otherElements["story-player"]
        XCTAssertTrue(waitForLabel(player, "Card 2 of 13", timeout: 9))
    }

    func testOpeningAdvancesAndYearPlayOpensMontage() {
        let app = launchedPlayer()
        app.buttons["opening-start"].tap()
        XCTAssertTrue(waitForLabel(app.otherElements["story-player"], "Card 2 of 13"))
        app.buttons["year-month-8"].tap()
        let viewer = app.buttons["month-viewer"]
        XCTAssertTrue(viewer.waitForExistence(timeout: 3))
        viewer.tap()
        let closed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == 0"),
            object: viewer
        )
        XCTAssertEqual(XCTWaiter().wait(for: [closed], timeout: 3), .completed)
        app.buttons["year-play"].tap()
        XCTAssertTrue(app.otherElements["year-montage"].waitForExistence(timeout: 3))
    }

    func testAlgorithmFeedbackWritesARow() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-session"]
        app.launch()
        let wrapped = app.buttons["wrapped-bubble"]
        XCTAssertTrue(wrapped.waitForExistence(timeout: 10))
        wrapped.tap()
        let maya = app.buttons["persona-maya"]
        XCTAssertTrue(maya.waitForExistence(timeout: 10))
        maya.tap()
        XCTAssertTrue(app.staticTexts["wrapped-ready"].waitForExistence(timeout: 40))

        app.terminate()
        app.launchArguments = ["--player", "--player-card", "4", "--player-paused"]
        app.launch()
        let more = app.buttons["feedback-more-0"]
        XCTAssertTrue(more.waitForExistence(timeout: 8))
        more.tap()
        XCTAssertTrue(app.staticTexts["Got it. We'll tune Explore."].waitForExistence(timeout: 15))
        XCTAssertTrue(app.otherElements["feedback-written"].waitForExistence(timeout: 3))
    }

    func testFeedSwatchExpands() {
        let app = XCUIApplication()
        app.launchArguments = ["--player", "--player-card", "3", "--player-paused"]
        app.launch()
        XCTAssertTrue(app.otherElements["story-player"].waitForExistence(timeout: 5))
        app.buttons["swatch-0"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["swatch-detail"].waitForExistence(timeout: 3))
    }

    func testRevealLandsOnThePersonality() {
        let app = XCUIApplication()
        app.launchArguments = ["--player", "--player-card", "11", "--player-paused"]
        app.launch()
        let player = app.otherElements["story-player"]
        XCTAssertTrue(player.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(player, "Card 11 of 13"))
        app.buttons["reveal-personality"].tap()
        XCTAssertTrue(waitForLabel(player, "Card 12 of 13"))
    }

    func testShareCardToggleCrossfades() {
        let app = XCUIApplication()
        app.launchArguments = ["--player", "--player-card", "13", "--player-paused"]
        app.launch()
        XCTAssertTrue(app.otherElements["story-player"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["share-identity"].waitForExistence(timeout: 3))
        let numbers = app.buttons["Numbers card"]
        XCTAssertTrue(numbers.waitForExistence(timeout: 3))
        XCTAssertFalse(numbers.isSelected)
        numbers.tap()
        XCTAssertTrue(numbers.isSelected)
        XCTAssertTrue(app.otherElements["share-numbers"].waitForExistence(timeout: 3))
    }

    func testPlayerCloseExits() {
        let app = launchedPlayer()
        let player = app.otherElements["story-player"]
        app.buttons["player-close"].tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == 0"), object: player)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 3), .completed)
    }

    private func launchedPlayer() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--player"]
        app.launch()
        XCTAssertTrue(app.otherElements["story-player"].waitForExistence(timeout: 5))
        return app
    }

    private func waitForLabel(_ element: XCUIElement, _ text: String, timeout: TimeInterval = 3) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", text),
            object: element
        )
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func drag(_ app: XCUIApplication, from start: CGVector, to end: CGVector) {
        let origin = app.coordinate(withNormalizedOffset: start)
        let destination = app.coordinate(withNormalizedOffset: end)
        origin.press(forDuration: 0.05, thenDragTo: destination)
    }
}
