import XCTest

final class OnboardingFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Coordinator 기반 테스트 (main 기존)

    func testOnboardingTransitionsToResultInSuccessScenario() {
        let app = launchApp(mode: "success")
        completeBasicOnboardingInput(in: app)

        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))
    }

    func testDelayedInvestmentDoesNotBlockResultTransition() {
        let app = launchApp(mode: "delayed_investment")
        completeBasicOnboardingInput(in: app)

        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))
    }

    func testRetryFromResultGoesBackToGenderSelection() {
        let app = launchApp(mode: "success")
        completeBasicOnboardingInput(in: app)

        let retryButton = app.buttons["onboarding.result.retry"]
        XCTAssertTrue(retryButton.waitForExistence(timeout: 20.0))
        XCTAssertTrue(retryButton.waitUntilHittable(timeout: 5.0))
        retryButton.tap()

        XCTAssertTrue(app.staticTexts["onboarding.gender.title"].waitForExistence(timeout: 5.0))
    }

    // MARK: - InvestmentOnboardingView E2E

    func testFullFlow_reachesInvestmentOnboardingView() {
        let app = launchApp(mode: "success")
        completeBasicOnboardingInput(in: app)

        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))

        // 투자 프로필 background Task 완료 대기
        sleep(2)
        startButton.tap()

        let investStartButton = app.buttons["투자 시작하기"]
        XCTAssertTrue(investStartButton.waitForExistence(timeout: 5), "투자 시작하기 버튼이 표시되어야 함")
    }

    func testInvestmentOnboarding_showsAllSections() {
        let app = launchApp(mode: "success")
        completeBasicOnboardingInput(in: app)

        // 사주 결과 → 시작하기
        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))

        // 투자 프로필 background Task 완료 대기 (0ms delay이지만 async 완료 보장)
        sleep(2)

        startButton.tap()

        // 히어로 타이틀 (mock은 .stable → "안정형")
        let heroTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '투자자입니다'")).firstMatch
        XCTAssertTrue(heroTitle.waitForExistence(timeout: 10), "히어로 타이틀이 표시되어야 함")

        // 섹션 순차 애니메이션 완료 대기 (6 x 300ms = 1.8s)
        sleep(2)

        // 나머지 섹션 검증
        XCTAssertTrue(app.staticTexts["사주가 말하는 이유"].exists, "사주 근거 섹션이 표시되어야 함")
        XCTAssertTrue(app.staticTexts["나에게 맞는 ETF"].exists, "ETF 섹션이 표시되어야 함")
        XCTAssertTrue(app.staticTexts["나의 투자 강점"].exists, "강점 섹션이 표시되어야 함")
        XCTAssertTrue(app.buttons["투자 시작하기"].exists, "CTA가 '투자 시작하기'여야 함")
    }

    // MARK: - 로딩/오류 상태 검증

    func testInvestmentOnboarding_showsLoadingState_whenDelayed() {
        let app = launchApp(mode: "delayed_investment")
        completeBasicOnboardingInput(in: app)

        // 사주 결과 → "시작하기" 즉시 탭 (투자 프로필은 4초 지연 중이므로 대기 없이 바로 탭)
        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))
        // sleep 없이 즉시 탭 → isLoading = true 상태에서 InvestmentOnboardingView 진입
        startButton.tap()

        // 투자 프로필이 아직 로딩 중 → ProgressView + "분석하는 중" 텍스트 표시
        let loadingText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "분석하는 중")
        ).firstMatch
        XCTAssertTrue(loadingText.waitForExistence(timeout: 5), "로딩 중 텍스트가 표시되어야 함")

        // "투자 시작하기" 버튼도 로딩 중에 노출되어야 함
        let ctaButton = app.buttons["투자 시작하기"]
        XCTAssertTrue(ctaButton.waitForExistence(timeout: 3), "로딩 중에도 '투자 시작하기' 버튼이 보여야 함")
    }

    func testInvestmentOnboarding_showsErrorState_whenFailed() {
        let app = launchApp(mode: "failed_investment")
        completeBasicOnboardingInput(in: app)

        // 사주 결과 → "시작하기" 탭
        let startButton = app.buttons["onboarding.result.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 12.0))
        XCTAssertTrue(startButton.waitUntilHittable(timeout: 3.0))
        sleep(2)
        startButton.tap()

        // 투자 프로필 로드 실패 → 오류 안내 메시지 표시
        let errorText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '불러오지 못했어요'")
        ).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 5), "오류 안내 메시지가 표시되어야 함")

        // "메인 화면에서 확인할 수 있어요" 안내 텍스트도 표시
        let guideText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '메인 화면에서'")
        ).firstMatch
        XCTAssertTrue(guideText.exists, "다음 행동 안내 텍스트가 표시되어야 함")

        // "투자 시작하기" 버튼이 오류 상태에서도 노출
        let ctaButton = app.buttons["투자 시작하기"]
        XCTAssertTrue(ctaButton.waitForExistence(timeout: 3), "오류 상태에서도 '투자 시작하기' 버튼이 보여야 함")
    }

    // MARK: - Helpers

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
