import Foundation

struct InvestmentProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let investmentType: InvestmentType
    let description: String
    let strengths: [String]
    let risks: [String]
    let recommendedETFs: [String]
    let sajuBasis: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case investmentType = "investment_type"
        case description, strengths, risks
        case recommendedETFs = "recommended_etfs"
        case sajuBasis = "saju_basis"
        case createdAt = "created_at"
    }
}

enum InvestmentType: String, Codable, CaseIterable {
    case aggressive = "aggressive"
    case stable = "stable"
    case value = "value"
    case growth = "growth"

    var displayName: String {
        switch self {
        case .aggressive: return "공격형"
        case .stable: return "안정형"
        case .value: return "가치투자형"
        case .growth: return "스타트업 추구형"
        }
    }

    var emoji: String {
        switch self {
        case .aggressive: return "🔥"
        case .stable: return "🛡️"
        case .value: return "💎"
        case .growth: return "🚀"
        }
    }

    var shortDescription: String {
        switch self {
        case .aggressive:
            return "리스크를 감수하고 높은 수익을 추구하는 타입"
        case .stable:
            return "안전한 투자로 꾸준한 수익을 추구하는 타입"
        case .value:
            return "기업의 본질적 가치에 집중하는 장기 투자 타입"
        case .growth:
            return "혁신 기업과 성장 가능성에 투자하는 타입"
        }
    }

    var recommendedETFs: [String] {
        switch self {
        case .aggressive:
            return ["QQQ (나스닥 100)", "TQQQ (나스닥 3배 레버리지)", "ARKK (혁신 기업)"]
        case .stable:
            return ["VOO (S&P 500)", "VTI (미국 전체 시장)", "BND (채권)"]
        case .value:
            return ["VTV (가치주)", "SCHD (배당 성장)", "BRK.B (버크셔 해서웨이)"]
        case .growth:
            return ["VUG (성장주)", "SOXX (반도체)", "IGV (소프트웨어)"]
        }
    }
}
