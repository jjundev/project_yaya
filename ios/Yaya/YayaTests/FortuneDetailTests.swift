import XCTest
@testable import Yaya

@MainActor
final class FortuneDetailTests: XCTestCase {

    // MARK: - FortuneContent 신규 필드 디코딩

    func testFortuneContent_decodesWithDetailFields() throws {
        let json = """
        {
            "summary": "테스트 요약",
            "love_score": 4,
            "money_score": 3,
            "health_score": 4,
            "work_score": 5,
            "lucky_number": 7,
            "lucky_color": "보라색",
            "advice": "조언",
            "love_detail": "사랑운 해설",
            "money_detail": "재물운 해설",
            "health_detail": "건강운 해설",
            "work_detail": "직장운 해설",
            "personal_message": "개인화 메시지"
        }
        """.data(using: .utf8)!

        let content = try JSONDecoder().decode(FortuneContent.self, from: json)
        XCTAssertEqual(content.loveDetail, "사랑운 해설")
        XCTAssertEqual(content.moneyDetail, "재물운 해설")
        XCTAssertEqual(content.healthDetail, "건강운 해설")
        XCTAssertEqual(content.workDetail, "직장운 해설")
        XCTAssertEqual(content.personalMessage, "개인화 메시지")
    }

    func testFortuneContent_decodesWithoutDetailFields() throws {
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
        XCTAssertNil(content.loveDetail)
        XCTAssertNil(content.moneyDetail)
        XCTAssertNil(content.healthDetail)
        XCTAssertNil(content.workDetail)
        XCTAssertNil(content.personalMessage)
    }

    // MARK: - Mock 데이터 신규 필드 검증

    func testMockFortuneContent_hasDetailFields() {
        let mock = AIService.shared.mockFortuneContent()
        XCTAssertNotNil(mock.loveDetail)
        XCTAssertNotNil(mock.moneyDetail)
        XCTAssertNotNil(mock.healthDetail)
        XCTAssertNotNil(mock.workDetail)
        XCTAssertNotNil(mock.personalMessage)
    }

    func testMockFortuneContent_detailFieldsNotEmpty() {
        let mock = AIService.shared.mockFortuneContent()
        XCTAssertFalse(mock.loveDetail?.isEmpty ?? true)
        XCTAssertFalse(mock.moneyDetail?.isEmpty ?? true)
        XCTAssertFalse(mock.healthDetail?.isEmpty ?? true)
        XCTAssertFalse(mock.workDetail?.isEmpty ?? true)
        XCTAssertFalse(mock.personalMessage?.isEmpty ?? true)
    }

    func testMockWeeklyFortuneContent_detailFieldsNil() {
        let mock = AIService.shared.mockWeeklyFortuneContent()
        XCTAssertNil(mock.loveDetail)
        XCTAssertNil(mock.moneyDetail)
        XCTAssertNil(mock.healthDetail)
        XCTAssertNil(mock.workDetail)
        XCTAssertNil(mock.personalMessage)
    }

    // MARK: - 공유 텍스트 생성

    func testShareText_containsAllComponents() {
        let content = AIService.shared.mockFortuneContent()
        let text = FortuneDetailView.shareText(content)

        XCTAssertTrue(text.contains("오늘의 운세"), "공유 텍스트에 제목 포함")
        XCTAssertTrue(text.contains(content.summary), "공유 텍스트에 요약 포함")
        XCTAssertTrue(text.contains("사랑"), "공유 텍스트에 사랑운 포함")
        XCTAssertTrue(text.contains("재물"), "공유 텍스트에 재물운 포함")
        XCTAssertTrue(text.contains("건강"), "공유 텍스트에 건강운 포함")
        XCTAssertTrue(text.contains("직장"), "공유 텍스트에 직장운 포함")
        XCTAssertTrue(text.contains("\(content.luckyNumber)"), "공유 텍스트에 행운의 숫자 포함")
        XCTAssertTrue(text.contains(content.luckyColor), "공유 텍스트에 행운의 색 포함")
        XCTAssertTrue(text.contains("YAYA"), "공유 텍스트에 앱 이름 포함")
    }

    func testShareText_scoreDotsFormat() {
        let content = AIService.shared.mockFortuneContent()
        let text = FortuneDetailView.shareText(content)

        // loveScore = 4이므로 ●●●●○ 패턴
        XCTAssertTrue(text.contains("●●●●○"), "사랑운 점수 4는 ●●●●○")
    }
}
