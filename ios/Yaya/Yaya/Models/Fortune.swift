import Foundation

struct Fortune: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let fortuneType: FortuneType
    let content: FortuneContent
    let date: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fortuneType = "fortune_type"
        case content
        case date
        case createdAt = "created_at"
    }
}

enum FortuneType: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .daily: return "오늘의 운세"
        case .weekly: return "주간 운세"
        case .monthly: return "월간 운세"
        case .yearly: return "연간 운세"
        }
    }

    var requiredTier: SubscriptionTier {
        switch self {
        case .daily: return .free
        case .weekly: return .basic
        case .monthly: return .standard
        case .yearly: return .premium
        }
    }
}

struct FortuneContent: Codable {
    let summary: String
    let loveScore: Int        // 1~5
    let moneyScore: Int       // 1~5
    let healthScore: Int      // 1~5
    let workScore: Int        // 1~5
    let luckyNumber: Int
    let luckyColor: String
    let advice: String
    let detailedAnalysis: String?
    let energySummary: String?     // 오늘의 에너지 한 줄 (헤더용)
    let elementInsight: String?    // 오행 에너지 인사이트 문구
    let loveDetail: String?        // 사랑운 AI 해설 (2~4문장)
    let moneyDetail: String?       // 재물운 AI 해설
    let healthDetail: String?      // 건강운 AI 해설
    let workDetail: String?        // 직장운 AI 해설
    let personalMessage: String?   // AI 개인화 편지

    enum CodingKeys: String, CodingKey {
        case summary
        case loveScore = "love_score"
        case moneyScore = "money_score"
        case healthScore = "health_score"
        case workScore = "work_score"
        case luckyNumber = "lucky_number"
        case luckyColor = "lucky_color"
        case advice
        case detailedAnalysis = "detailed_analysis"
        case energySummary = "energy_summary"
        case elementInsight = "element_insight"
        case loveDetail = "love_detail"
        case moneyDetail = "money_detail"
        case healthDetail = "health_detail"
        case workDetail = "work_detail"
        case personalMessage = "personal_message"
    }
}

struct SajuAnalysis: Codable {
    let summary: String
    let personality: String
    let strengths: [String]
    let weaknesses: [String]
    let wealthFortune: String
    let relationships: String
    let career: String
    let fiveElements: FiveElements

    enum CodingKeys: String, CodingKey {
        case summary, personality, strengths, weaknesses
        case wealthFortune = "wealth_fortune"
        case relationships, career
        case fiveElements = "five_elements"
    }
}

struct FiveElements: Codable {
    let wood: Int   // 목
    let fire: Int   // 화
    let earth: Int  // 토
    let metal: Int  // 금
    let water: Int  // 수

    var dominant: String {
        let elements = [("목(木)", wood), ("화(火)", fire), ("토(土)", earth), ("금(金)", metal), ("수(水)", water)]
        return elements.max(by: { $0.1 < $1.1 })?.0 ?? "균형"
    }
}
