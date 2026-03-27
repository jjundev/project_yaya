import Foundation

// AI API를 통한 사주 분석 및 운세 생성 서비스
final class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - 사주 분석

    func analyzeSaju(birthDate: Date, birthTime: BirthTime?, gender: Gender) async throws -> SajuAnalysis {
        let prompt = buildSajuPrompt(birthDate: birthDate, birthTime: birthTime, gender: gender)

        // TODO: Supabase Edge Function (calculate-saju) 호출로 변경
        // 서버에서 AI API를 호출하여 API 키 노출 방지
        let result: SajuAnalysis = try await SupabaseService.shared.callEdgeFunction(
            name: "calculate-saju",
            body: [
                "birth_date": ISO8601DateFormatter().string(from: birthDate),
                "birth_time": birthTime?.rawValue ?? "모름",
                "gender": gender.rawValue
            ]
        )
        return result
    }

    // MARK: - 운세 생성

    func generateFortune(sajuAnalysis: SajuAnalysis, type: FortuneType, date: Date) async throws -> FortuneContent {
        // TODO: Supabase Edge Function (daily-fortune) 호출
        let result: FortuneContent = try await SupabaseService.shared.callEdgeFunction(
            name: "daily-fortune",
            body: [
                "saju_summary": sajuAnalysis.summary,
                "fortune_type": type.rawValue,
                "date": ISO8601DateFormatter().string(from: date)
            ]
        )
        return result
    }

    // MARK: - 투자 성향 분석

    func analyzeInvestmentType(sajuAnalysis: SajuAnalysis) async throws -> InvestmentProfile {
        // TODO: Supabase Edge Function (investment-personality) 호출
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
