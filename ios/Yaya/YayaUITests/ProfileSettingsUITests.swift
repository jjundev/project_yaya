import XCTest

final class ProfileSettingsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - 사주 재분석

    func test_reanalysisButton_exists() {
        let app = launchMainTab()
        navigateToProfile(in: app)

        let button = app.buttons["settings.reanalysis"]
        scrollToElement(button, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 3), "사주 재분석 버튼이 표시되어야 함")
    }

    func test_reanalysisButton_showsConfirmationDialog() {
        let app = launchMainTab()
        navigateToProfile(in: app)

        let button = app.buttons["settings.reanalysis"]
        scrollToElement(button, in: app)
        button.tap()

        let alert = app.alerts["사주 재분석"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "사주 재분석 확인 다이얼로그가 표시되어야 함")
        XCTAssertTrue(alert.buttons["확인"].exists, "확인 버튼이 있어야 함")
        XCTAssertTrue(alert.buttons["취소"].exists, "취소 버튼이 있어야 함")
    }

    func test_reanalysisDialog_cancel_staysOnProfile() {
        let app = launchMainTab()
        navigateToProfile(in: app)

        let button = app.buttons["settings.reanalysis"]
        scrollToElement(button, in: app)
        button.tap()

        let alert = app.alerts["사주 재분석"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["취소"].tap()

        XCTAssertTrue(app.navigationBars["마이페이지"].waitForExistence(timeout: 3))
    }

    func test_reanalysisDialog_confirm_dismissesAlert() {
        // Note: UITEST_MAIN_TAB 모드는 needsOnboarding 무시하고 MainTabView를 강제 표시하므로
        // 실제 온보딩 전환은 검증 불가. 다이얼로그 확인 탭 후 alert가 닫히는지만 검증.
        let app = launchMainTab()
        navigateToProfile(in: app)

        let button = app.buttons["settings.reanalysis"]
        scrollToElement(button, in: app)
        button.tap()

        let alert = app.alerts["사주 재분석"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["확인"].tap()

        // alert가 닫혀야 함
        XCTAssertFalse(alert.waitForExistence(timeout: 2), "확인 후 다이얼로그가 닫혀야 함")
    }

    // MARK: - 로그아웃

    func test_logoutButton_showsConfirmationDialog() {
        let app = launchMainTab()
        navigateToProfile(in: app)

        let button = app.buttons["settings.logout"]
        scrollToElement(button, in: app)
        button.tap()

        let alert = app.alerts["로그아웃"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "로그아웃 확인 다이얼로그가 표시되어야 함")
        XCTAssertTrue(alert.buttons["확인"].exists, "확인 버튼이 있어야 함")
        XCTAssertTrue(alert.buttons["취소"].exists, "취소 버튼이 있어야 함")
    }

    func test_logoutDialog_cancel_staysOnProfile() {
        let app = launchMainTab()
        navigateToProfile(in: app)

        let button = app.buttons["settings.logout"]
        scrollToElement(button, in: app)
        button.tap()

        let alert = app.alerts["로그아웃"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["취소"].tap()

        XCTAssertTrue(app.navigationBars["마이페이지"].waitForExistence(timeout: 3))
    }

    // MARK: - 알림 설정

    func test_notificationSettings_navigation() {
        let app = launchMainTab()
        navigateToProfile(in: app)

        let notificationLink = app.buttons["settings.notification"]
        scrollToElement(notificationLink, in: app)
        notificationLink.tap()

        let toggle = app.switches["settings.notification.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3), "알림 토글이 표시되어야 함")
    }

    // MARK: - 이용약관 / 개인정보처리방침

    func test_termsAndPrivacy_labelsExist() {
        let app = launchMainTab()
        navigateToProfile(in: app)

        // 설정 섹션까지 스크롤
        let list = app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch
        list.swipeUp()

        let termsLabel = app.staticTexts["이용약관"]
        let privacyLabel = app.staticTexts["개인정보 처리방침"]
        XCTAssertTrue(termsLabel.waitForExistence(timeout: 3), "이용약관 항목이 표시되어야 함")
        XCTAssertTrue(privacyLabel.exists, "개인정보 처리방침 항목이 표시되어야 함")
    }

    // MARK: - Helpers

    private func launchMainTab() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_MAIN_TAB"] = "1"
        app.launch()
        return app
    }

    private func navigateToProfile(in app: XCUIApplication) {
        let profileTab = app.tabBars.buttons["마이페이지"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 5) {
        let list = app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return }
            list.swipeUp()
        }
    }
}
