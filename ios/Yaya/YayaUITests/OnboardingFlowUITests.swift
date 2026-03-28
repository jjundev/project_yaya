import XCTest

final class OnboardingFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingTransitionsToResultInSuccessScenario() {
        let app = launchApp(mode: "success")
        completeBasicOnboardingInput(in: app)

        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))
        XCTAssertTrue(startButton.exists)
    }

    func testDelayedInvestmentDoesNotBlockResultTransition() {
        let app = launchApp(mode: "delayed_investment")
        completeBasicOnboardingInput(in: app)

        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))
    }

    func testFailedInvestmentStillShowsResultAndSupportsRetry() {
        let app = launchApp(mode: "failed_investment")
        completeBasicOnboardingInput(in: app)

        let retryButton = app.buttons["onboarding.result.retry"]
        XCTAssertTrue(retryButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(retryButton.waitUntilHittable(timeout: 3.0))
        retryButton.tap()

        XCTAssertTrue(app.staticTexts["onboarding.gender.title"].waitForExistence(timeout: 5.0))
    }

    private func launchApp(mode: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_MOCK_ANALYSIS"] = mode
        app.launch()
        return app
    }

    private func completeBasicOnboardingInput(in app: XCUIApplication) {
        let maleButton = app.buttons["onboarding.gender.male"]
        XCTAssertTrue(maleButton.waitForExistence(timeout: 3.0))
        maleButton.tap()

        let nextGenderButton = app.buttons["onboarding.next.gender"]
        XCTAssertTrue(nextGenderButton.isEnabled)
        nextGenderButton.tap()

        let nextBirthButton = app.buttons["onboarding.next.birth"]
        XCTAssertTrue(nextBirthButton.waitForExistence(timeout: 3.0))
        nextBirthButton.tap()
    }
}

private extension XCUIElement {
    func waitUntilHittable(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
