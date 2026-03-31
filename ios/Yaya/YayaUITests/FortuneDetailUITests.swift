import XCTest

final class FortuneDetailUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - 홈 → 상세 진입

    func testDailyCardTap_navigatesToDetailView() {
        let app = launchApp()

        let dailyCard = app.buttons["fortune.daily.card"]
        XCTAssertTrue(dailyCard.waitForExistence(timeout: 10), "오늘의 운세 카드가 표시되어야 함")
        dailyCard.tap()

        let header = app.otherElements["fortune.detail.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "상세 화면 헤더가 표시되어야 함")
    }

    // MARK: - 영역별 섹션 표시

    func testDetailView_showsAllScoreSections() {
        let app = launchApp()
        navigateToDetail(app: app)

        XCTAssertTrue(app.otherElements["fortune.detail.love"].waitForExistence(timeout: 5), "사랑운 섹션이 표시되어야 함")
        XCTAssertTrue(app.otherElements["fortune.detail.money"].exists, "재물운 섹션이 표시되어야 함")
        XCTAssertTrue(app.otherElements["fortune.detail.health"].exists, "건강운 섹션이 표시되어야 함")
        XCTAssertTrue(app.otherElements["fortune.detail.work"].exists, "직장운 섹션이 표시되어야 함")
    }

    // MARK: - AI 개인화 메시지

    func testDetailView_showsPersonalMessage() {
        let app = launchApp()
        navigateToDetail(app: app)

        // 스크롤 하단에 있을 수 있으므로 스와이프
        app.swipeUp()

        let personalMessage = app.otherElements["fortune.detail.personalMessage"]
        XCTAssertTrue(personalMessage.waitForExistence(timeout: 5), "AI 개인화 메시지 섹션이 표시되어야 함")
    }

    // MARK: - 행운 아이템

    func testDetailView_showsLuckyItems() {
        let app = launchApp()
        navigateToDetail(app: app)

        app.swipeUp()

        let luckyItems = app.otherElements["fortune.detail.luckyItems"]
        XCTAssertTrue(luckyItems.waitForExistence(timeout: 5), "행운 아이템 섹션이 표시되어야 함")
    }

    // MARK: - 공유 버튼

    func testDetailView_showsShareButton() {
        let app = launchApp()
        navigateToDetail(app: app)

        app.swipeUp()

        let shareButton = app.buttons["fortune.detail.share"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "공유 버튼이 표시되어야 함")
    }

    // MARK: - 뒤로가기

    func testDetailView_backNavigatesToHome() {
        let app = launchApp()
        navigateToDetail(app: app)

        // 네비게이션 바 뒤로가기 버튼
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        backButton.tap()

        // 홈으로 복귀 확인
        let dailyCard = app.buttons["fortune.daily.card"]
        XCTAssertTrue(dailyCard.waitForExistence(timeout: 5), "홈 화면으로 복귀해야 함")
    }

    // MARK: - Mock 운세 플로우 통합 테스트

    /// mock 사용자로 운세 탭 진입 → 카드 3종(일일, 오행, 주간) 표시 → 상세 화면 전환 확인
    func testMockUser_fortuneFlowEndToEnd() {
        let app = launchApp()

        // 일일 운세 카드 표시 확인
        let dailyCard = app.buttons["fortune.daily.card"]
        XCTAssertTrue(dailyCard.waitForExistence(timeout: 15), "mock 일일 운세 카드가 표시되어야 함")

        // 오행 분석 카드 표시 확인
        let elementCard = app.otherElements["fortune.element.card"]
        XCTAssertTrue(elementCard.waitForExistence(timeout: 5), "mock 오행 분석 카드가 표시되어야 함")

        // 주간 운세 카드 표시 확인 (스크롤 필요할 수 있음)
        app.swipeUp()
        let weeklyCard = app.otherElements["fortune.weekly.card"]
        XCTAssertTrue(weeklyCard.waitForExistence(timeout: 5), "mock 주간 운세 카드가 표시되어야 함")

        // 상단으로 복귀 후 상세 화면 진입
        app.swipeDown()
        let dailyCardAgain = app.buttons["fortune.daily.card"]
        XCTAssertTrue(dailyCardAgain.waitForExistence(timeout: 5))
        dailyCardAgain.tap()

        // FortuneDetailView 내용 확인
        let header = app.otherElements["fortune.detail.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "상세 화면 헤더가 표시되어야 함")
        XCTAssertTrue(app.otherElements["fortune.detail.love"].waitForExistence(timeout: 5), "사랑운 점수가 표시되어야 함")
    }

    // MARK: - Helpers

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_MAIN_TAB"] = "1"
        app.launch()
        return app
    }

    private func navigateToDetail(app: XCUIApplication) {
        let dailyCard = app.buttons["fortune.daily.card"]
        XCTAssertTrue(dailyCard.waitForExistence(timeout: 10))
        dailyCard.tap()
    }
}
