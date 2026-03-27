import Foundation

final class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - 사주 분석

    func analyzeSaju(birthDate: Date, birthTime: BirthTime?, gender: Gender) async throws -> SajuAnalysis {
        // Edge Function 미배포 상태 — Mock 데이터 사용
        // TODO: 실제 Edge Function 배포 후 아래 코드로 교체
        // let result: SajuAnalysis = try await SupabaseService.shared.callEdgeFunction(
        //     name: "calculate-saju",
        //     body: [
        //         "birth_date": ISO8601DateFormatter().string(from: birthDate),
        //         "birth_time": birthTime?.rawValue ?? "모름",
        //         "gender": gender.rawValue
        //     ]
        // )
        // return result

        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 로딩 연출
        return mockSajuAnalysis(gender: gender)
    }

    // MARK: - 운세 생성

    func generateFortune(sajuAnalysis: SajuAnalysis, type: FortuneType, date: Date) async throws -> FortuneContent {
        // TODO: 실제 Edge Function 배포 후 교체
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return mockFortuneContent()
    }

    // MARK: - 투자 성향 분석

    func analyzeInvestmentType(sajuAnalysis: SajuAnalysis) async throws -> InvestmentProfile {
        // TODO: 실제 Edge Function 배포 후 교체
        let result: InvestmentProfile = try await SupabaseService.shared.callEdgeFunction(
            name: "investment-personality",
            body: [
                "saju_summary": sajuAnalysis.summary,
                "personality": sajuAnalysis.personality,
                "five_elements": [
                    "wood": sajuAnalysis.fiveElements.wood,
                    "fire": sajuAnalysis.fiveElements.fire,
                    "earth": sajuAnalysis.fiveElements.earth,
                    "metal": sajuAnalysis.fiveElements.metal,
                    "water": sajuAnalysis.fiveElements.water
                ] as [String: Any]
            ]
        )
        return result
    }

    // MARK: - Mock Data

    func mockSajuAnalysis(gender: Gender) -> SajuAnalysis {
        SajuAnalysis(
            summary: "화(火)와 목(木)의 기운이 강한 사주입니다. 창의적이고 진취적인 성향을 가지고 있으며, 리더십이 뛰어납니다.",
            personality: "열정적이고 추진력이 강한 성격입니다. 새로운 도전을 두려워하지 않으며, 주변 사람들에게 긍정적인 에너지를 전달합니다. 다만 때로는 성급한 판단을 할 수 있으니 신중함이 필요합니다.",
            strengths: ["리더십", "창의력", "추진력", "사교성", "적응력"],
            weaknesses: ["성급함", "과도한 욕심"],
            wealthFortune: "재물운이 양호합니다. 특히 올해 하반기에 투자 기회가 찾아올 수 있습니다. 안정적인 자산 배분과 장기 투자 전략이 유리합니다.",
            relationships: "대인관계가 원만하며, 새로운 인연이 좋은 기회를 가져다줄 수 있습니다.",
            career: "창의적인 분야에서 두각을 나타낼 수 있습니다. 리더 역할에 적합합니다.",
            fiveElements: FiveElements(wood: 30, fire: 35, earth: 15, metal: 10, water: 10)
        )
    }

    func mockFortuneContent() -> FortuneContent {
        FortuneContent(
            summary: "오늘은 새로운 시작에 좋은 날입니다. 그동안 망설이던 일이 있다면 오늘 첫 걸음을 내딛어 보세요.",
            loveScore: 4,
            moneyScore: 3,
            healthScore: 4,
            workScore: 5,
            luckyNumber: 7,
            luckyColor: "보라색",
            advice: "오전 중에 중요한 결정을 내리면 좋은 결과를 얻을 수 있습니다.",
            detailedAnalysis: nil
        )
    }

    // MARK: - Private

    private func buildSajuPrompt(birthDate: Date, birthTime: BirthTime?, gender: Gender) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        let dateString = formatter.string(from: birthDate)
        let timeString = birthTime?.displayName ?? "모름"
        let genderString = gender.displayName

        return """
        다음 정보로 사주팔자를 분석해주세요:
        - 생년월일: \(dateString)
        - 태어난 시: \(timeString)
        - 성별: \(genderString)

        천간, 지지, 십신, 오행을 분석하고 다음을 포함해주세요:
        1. 사주 요약
        2. 성격 분석
        3. 장점과 단점
        4. 재물운
        5. 대인관계
        6. 적합한 직업/진로
        7. 오행 비율 (목/화/토/금/수 각각 0~100)
        """
    }
}
