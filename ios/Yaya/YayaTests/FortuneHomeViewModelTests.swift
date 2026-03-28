import XCTest
@testable import Yaya

@MainActor
final class FortuneHomeViewModelTests: XCTestCase {

    // MARK: - hasDateChanged

    func testHasDateChanged_returnsfalse_whenNeverLoaded() {
        let vm = FortuneViewModel()
        XCTAssertFalse(vm.hasDateChanged(), "운세를 한 번도 로드하지 않았으면 false")
    }

    // MARK: - 초기 상태

    func testInitialState() {
        let vm = FortuneViewModel()
        XCTAssertNil(vm.dailyFortune)
        XCTAssertNil(vm.weeklyFortune)
        XCTAssertNil(vm.sajuAnalysis)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - FortuneContent 모델

    func testFortuneContent_decodesWithNewFields() throws {
        let json = """
        {
            "summary": "테스트 요약",
            "love_score": 3,
            "money_score": 4,
            "health_score": 2,
            "work_score": 5,
            "lucky_number": 7,
            "lucky_color": "빨간색",
            "advice": "테스트 조언",
            "energy_summary": "에너지 한 줄",
            "element_insight": "오행 인사이트"
        }
        """.data(using: .utf8)!

        let content = try JSONDecoder().decode(FortuneContent.self, from: json)
        XCTAssertEqual(content.summary, "테스트 요약")
        XCTAssertEqual(content.loveScore, 3)
        XCTAssertEqual(content.moneyScore, 4)
        XCTAssertEqual(content.healthScore, 2)
        XCTAssertEqual(content.workScore, 5)
        XCTAssertEqual(content.luckyNumber, 7)
        XCTAssertEqual(content.luckyColor, "빨간색")
        XCTAssertEqual(content.advice, "테스트 조언")
        XCTAssertEqual(content.energySummary, "에너지 한 줄")
        XCTAssertEqual(content.elementInsight, "오행 인사이트")
    }

    func testFortuneContent_decodesWithoutOptionalFields() throws {
        let json = """
        {
            "summary": "테스트",
            "love_score": 1,
            "money_score": 1,
            "health_score": 1,
            "work_score": 1,
            "lucky_number": 1,
            "lucky_color": "파랑",
            "advice": "조언"
        }
        """.data(using: .utf8)!

        let content = try JSONDecoder().decode(FortuneContent.self, from: json)
        XCTAssertNil(content.detailedAnalysis)
        XCTAssertNil(content.energySummary)
        XCTAssertNil(content.elementInsight)
    }

    // MARK: - FiveElements

    func testFiveElements_dominant() {
        let elements = FiveElements(wood: 10, fire: 40, earth: 20, metal: 15, water: 15)
        XCTAssertEqual(elements.dominant, "화(火)")
    }

    func testFiveElements_dominant_wood() {
        let elements = FiveElements(wood: 50, fire: 10, earth: 20, metal: 10, water: 10)
        XCTAssertEqual(elements.dominant, "목(木)")
    }

    // MARK: - FortuneType

    func testFortuneType_requiredTier() {
        XCTAssertEqual(FortuneType.daily.requiredTier, .free)
        XCTAssertEqual(FortuneType.weekly.requiredTier, .basic)
        XCTAssertEqual(FortuneType.monthly.requiredTier, .standard)
        XCTAssertEqual(FortuneType.yearly.requiredTier, .premium)
    }

    func testFortuneType_displayName() {
        XCTAssertEqual(FortuneType.daily.displayName, "오늘의 운세")
        XCTAssertEqual(FortuneType.weekly.displayName, "주간 운세")
    }

    // MARK: - Mock 데이터 검증

    func testMockFortuneContent_hasEnergySummary() {
        let mock = AIService.shared.mockFortuneContent()
        XCTAssertNotNil(mock.energySummary)
        XCTAssertFalse(mock.energySummary?.isEmpty ?? true)
    }

    func testMockFortuneContent_hasElementInsight() {
        let mock = AIService.shared.mockFortuneContent()
        XCTAssertNotNil(mock.elementInsight)
        XCTAssertFalse(mock.elementInsight?.isEmpty ?? true)
    }

    func testMockWeeklyFortuneContent_hasDetailedAnalysis() {
        let mock = AIService.shared.mockWeeklyFortuneContent()
        XCTAssertNotNil(mock.detailedAnalysis)
        XCTAssertFalse(mock.detailedAnalysis?.isEmpty ?? true)
    }

    func testMockFortuneContent_scoresInRange() {
        let mock = AIService.shared.mockFortuneContent()
        XCTAssertTrue((1...5).contains(mock.loveScore))
        XCTAssertTrue((1...5).contains(mock.moneyScore))
        XCTAssertTrue((1...5).contains(mock.healthScore))
        XCTAssertTrue((1...5).contains(mock.workScore))
    }
}
