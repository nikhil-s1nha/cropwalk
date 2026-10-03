import XCTest

/// Taps through every placeholder screen with mocks. Keeps the Sat 6 pm checkpoint honest:
/// as real screens replace placeholders, update the identifiers they expose.
final class PlaceholderFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-mock"]
        app.launch()
    }

    private func go(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["go.\(id)"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "missing button go.\(id)", file: file, line: line)
        button.tap()
        XCTAssertTrue(app.descendants(matching: .any)["screen.\(id)"].waitForExistence(timeout: 5), "missing screen \(id)", file: file, line: line)
    }

    func testFullWalkFlowReachesEveryScreen() {
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 10))
        for id in ["language", "consent", "boundary", "problemSpots", "routePreview", "walk"] { go(id) }
        // Stop 1: the full photo path.
        for id in ["stopInstructions-1", "leafCount-1", "camera-1", "photoCheck-1", "voiceNote-1", "stopResult-1"] { go(id) }
        // Stops 2–10: count then straight to result.
        for k in 2...10 {
            go("stopInstructions-\(k)")
            go("leafCount-\(k)")
            go("stopResult-\(k)")
        }
        go("summary")
        go("sendCooperative")
        go("outbox")
        app.buttons["go.home"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 5))
    }

    func testEndScreenBranchesAndHomeEntries() {
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 10))
        for id in ["settings", "pastWalks", "outbox"] {
            go(id)
            app.buttons["go.home"].tap()
        }
    }
}
