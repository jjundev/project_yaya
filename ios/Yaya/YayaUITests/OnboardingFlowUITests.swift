import XCTest

final class OnboardingFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UITEST_MOCK_ANALYSIS"] = "1"
    }

    // MARK: - Mock 모드 진입 확인

    func test_mockMode_showsOnboardingNotLogin() {
        app.launch()
        // 로그인 화면이 아닌 온보딩(성별 선택) 화면이 표시되어야 함
        let genderTitle = app.staticTexts["성별을 선택해주세요"]
        XCTAssertTrue(genderTitle.waitForExistence(timeout: 5), "Mock 모드에서 온보딩 화면이 표시되어야 함")
        // 로그인 버튼이 없어야 함
        let kakaoButton = app.buttons["카카오로 시작하기"]
        XCTAssertFalse(kakaoButton.exists, "Mock 모드에서 로그인 버튼이 없어야 함")
    }

    func test_mockMode_genderSelectionWorks() {
        app.launch()
        let femaleButton = app.buttons["여성"]
        XCTAssertTrue(femaleButton.waitForExistence(timeout: 5))
        femaleButton.tap()
        let genderNext = app.buttons["gender_next"]
        XCTAssertTrue(genderNext.isEnabled, "성별 선택 후 다음 버튼이 활성화되어야 함")
    }

    func test_mockMode_birthScreenAppears() {
        app.launch()
        app.buttons["여성"].firstMatch.tap()
        app.buttons["gender_next"].firstMatch.tap()
        let birthTitle = app.staticTexts["생년월일을 입력해주세요"]
        XCTAssertTrue(birthTitle.waitForExistence(timeout: 5), "생년월일 화면이 표시되어야 함")
    }

    // MARK: - 온보딩 → 사주 결과 → 투자 정체성 화면 전체 플로우

    func test_fullOnboardingFlow_reachesInvestmentOnboardingView() {
        app.launch()

        // Step 1: 성별 선택
        let femaleButton = app.buttons["여성"]
        XCTAssertTrue(femaleButton.waitForExistence(timeout: 5), "성별 선택 화면이 표시되어야 함")
        femaleButton.tap()

        // "다음" 탭 (성별 → 생년월일)
        let genderNext = app.buttons["gender_next"]
        XCTAssertTrue(genderNext.waitForExistence(timeout: 3), "성별 다음 버튼이 존재해야 함")
        genderNext.tap()

        // Step 2: 생년월일 — "다음" 탭 (기본값 사용)
        tapBirthNext()

        // Step 3: 분석 로딩 → 사주 결과 화면
        let startButton = app.buttons["시작하기"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 15), "사주 결과 화면의 시작하기 버튼이 표시되어야 함")

        // "시작하기" 탭 → InvestmentOnboardingView로 이동
        startButton.tap()

        // 투자 정체성 화면 검증
        let investStartButton = app.buttons["투자 시작하기"]
        XCTAssertTrue(investStartButton.waitForExistence(timeout: 5), "투자 시작하기 버튼이 표시되어야 함")
    }

    // MARK: - 투자 정체성 화면 히어로 섹션 검증

    func test_investmentOnboarding_showsHeroSection() {
        navigateToInvestmentOnboarding()

        // 히어로 타이틀: "당신은 공격형 투자자입니다" (기본 mock은 aggressive)
        let heroTitle = app.staticTexts["당신은 공격형 투자자입니다"]
        XCTAssertTrue(heroTitle.waitForExistence(timeout: 5), "히어로 타이틀이 표시되어야 함")

        // 이모지 표시 확인
        let emoji = app.staticTexts["🔥"]
        XCTAssertTrue(emoji.exists, "투자 타입 이모지가 표시되어야 함")
    }

    // MARK: - 사주 근거 섹션 검증

    func test_investmentOnboarding_showsSajuBasisSection() {
        navigateToInvestmentOnboarding()

        let basisLabel = app.staticTexts["사주가 말하는 이유"]
        XCTAssertTrue(basisLabel.waitForExistence(timeout: 5), "사주 근거 섹션 라벨이 표시되어야 함")
    }

    // MARK: - ETF 섹션 검증

    func test_investmentOnboarding_showsETFSection() {
        navigateToInvestmentOnboarding()

        let etfLabel = app.staticTexts["나에게 맞는 ETF"]
        XCTAssertTrue(etfLabel.waitForExistence(timeout: 5), "ETF 섹션 라벨이 표시되어야 함")
    }

    // MARK: - 강점 섹션 검증

    func test_investmentOnboarding_showsStrengthsSection() {
        navigateToInvestmentOnboarding()

        let strengthsLabel = app.staticTexts["나의 투자 강점"]
        XCTAssertTrue(strengthsLabel.waitForExistence(timeout: 5), "강점 섹션 라벨이 표시되어야 함")
    }

    // MARK: - 리스크 섹션 검증

    func test_investmentOnboarding_showsRisksSection() {
        navigateToInvestmentOnboarding()

        let risksLabel = app.staticTexts["주의할 점"]
        XCTAssertTrue(risksLabel.waitForExistence(timeout: 5), "리스크 섹션 라벨이 표시되어야 함")
    }

    // MARK: - CTA 버튼 텍스트 검증

    func test_investmentOnboarding_ctaButtonText() {
        navigateToInvestmentOnboarding()

        let ctaButton = app.buttons["투자 시작하기"]
        XCTAssertTrue(ctaButton.waitForExistence(timeout: 5), "CTA 버튼이 '투자 시작하기' 텍스트여야 함")
    }

    // MARK: - 타입별 히어로 검증 (안정형)

    func test_investmentOnboarding_stableType_showsCorrectHero() {
        app.launchEnvironment["UITEST_INVESTMENT_TYPE"] = "stable"
        navigateToInvestmentOnboarding()

        let heroTitle = app.staticTexts["당신은 안정형 투자자입니다"]
        XCTAssertTrue(heroTitle.waitForExistence(timeout: 5), "안정형 히어로 타이틀이 표시되어야 함")

        let emoji = app.staticTexts["🛡️"]
        XCTAssertTrue(emoji.exists, "안정형 이모지가 표시되어야 함")
    }

    // MARK: - 타입별 히어로 검증 (가치투자형)

    func test_investmentOnboarding_valueType_showsCorrectHero() {
        app.launchEnvironment["UITEST_INVESTMENT_TYPE"] = "value"
        navigateToInvestmentOnboarding()

        let heroTitle = app.staticTexts["당신은 가치투자형 투자자입니다"]
        XCTAssertTrue(heroTitle.waitForExistence(timeout: 5), "가치투자형 히어로 타이틀이 표시되어야 함")

        let emoji = app.staticTexts["💎"]
        XCTAssertTrue(emoji.exists, "가치투자형 이모지가 표시되어야 함")
    }

    // MARK: - 타입별 히어로 검증 (성장추구형)

    func test_investmentOnboarding_growthType_showsCorrectHero() {
        app.launchEnvironment["UITEST_INVESTMENT_TYPE"] = "growth"
        navigateToInvestmentOnboarding()

        let heroTitle = app.staticTexts["당신은 스타트업 추구형 투자자입니다"]
        XCTAssertTrue(heroTitle.waitForExistence(timeout: 5), "성장추구형 히어로 타이틀이 표시되어야 함")

        let emoji = app.staticTexts["🚀"]
        XCTAssertTrue(emoji.exists, "성장추구형 이모지가 표시되어야 함")
    }

    // MARK: - Helper

    /// DatePicker가 화면을 차지하여 birth_next 버튼이 안 보일 수 있음 — coordinate 기반 강제 탭
    private func tapBirthNext() {
        let birthNext = app.buttons["birth_next"]
        _ = birthNext.waitForExistence(timeout: 3)
        if birthNext.isHittable {
            birthNext.tap()
        } else {
            // 버튼이 화면 밖에 있으면 해당 좌표로 직접 탭
            birthNext.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func navigateToInvestmentOnboarding() {
        app.launch()

        // Step 1: 성별 선택
        let femaleButton = app.buttons["여성"]
        _ = femaleButton.waitForExistence(timeout: 5)
        femaleButton.tap()

        // 성별 → 생년월일
        let genderNext = app.buttons["gender_next"]
        _ = genderNext.waitForExistence(timeout: 3)
        genderNext.tap()

        // Step 2: 생년월일 → 분석
        tapBirthNext()

        // Step 3: 사주 결과 → 시작하기
        let startButton = app.buttons["시작하기"]
        _ = startButton.waitForExistence(timeout: 15)
        startButton.tap()

        // InvestmentOnboardingView 도달 대기
        let ctaButton = app.buttons["투자 시작하기"]
        _ = ctaButton.waitForExistence(timeout: 5)
    }
}
