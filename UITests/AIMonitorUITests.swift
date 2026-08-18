import XCTest

final class AIMonitorUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingFlow() {
        let app = launch(scenario: "empty", onboarding: false)
        openMenuBarPopup(app)
        XCTAssertTrue(app.staticTexts["Welcome to AI Monitor"].waitForExistence(timeout: 3))
        app.buttons["Get Started"].click()
        XCTAssertTrue(app.staticTexts["Private by default"].waitForExistence(timeout: 2))
        app.buttons["Continue"].click()
        XCTAssertTrue(app.staticTexts["Connect your first account"].waitForExistence(timeout: 2))
    }

    func testAddAccountSheet() {
        let app = launch(scenario: "empty")
        openMenuBarPopup(app)
        app.buttons["Add Account"].click()
        XCTAssertTrue(app.staticTexts["Codex / OpenAI"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Kling"].exists)
    }

    func testDisconnectedState() {
        let app = launch(scenario: "disconnected")
        openMenuBarPopup(app)
        XCTAssertTrue(app.staticTexts["Login required"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Codex Personal"].exists)
    }

    func testPopupWithMockData() {
        let app = launch(scenario: "mock")
        openMenuBarPopup(app)
        XCTAssertTrue(app.staticTexts["Codex Preview"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["82% left"].exists)
    }

    func testConnectionError() {
        let app = launch(scenario: "error")
        openMenuBarPopup(app)
        XCTAssertTrue(app.alerts["AI Monitor"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Connection failed in test preview."].exists)
    }

    private func launch(scenario: String, onboarding: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["AIMONITOR_UI_SCENARIO"] = scenario
        app.launchArguments += ["-hasCompletedOnboarding", onboarding ? "YES" : "NO"]
        app.launch()
        return app
    }

    private func openMenuBarPopup(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let item = app.menuBars.statusItems["AI Monitor"]
        XCTAssertTrue(item.waitForExistence(timeout: 5), "AI Monitor status item did not appear", file: file, line: line)
        item.click()
    }
}
