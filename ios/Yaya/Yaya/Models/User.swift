import Foundation

struct AppUser: Codable, Identifiable {
    let id: UUID
    var email: String?
    var phone: String?
    var nickname: String?
    var gender: Gender?
    var birthDate: Date?
    var birthTime: BirthTime?
    var isLunar: Bool
    var referralCode: String?
    var referredBy: UUID?
    var referralCount: Int
    var subscriptionTier: SubscriptionTier
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, nickname, gender
        case birthDate = "birth_date"
        case birthTime = "birth_time"
        case isLunar = "is_lunar"
        case referralCode = "referral_code"
        case referredBy = "referred_by"
        case referralCount = "referral_count"
        case subscriptionTier = "subscription_tier"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum Gender: String, Codable, CaseIterable {
    case male
    case female

    var displayName: String {
        switch self {
        case .male: return "남성"
        case .female: return "여성"
        }
    }
}

enum BirthTime: String, Codable, CaseIterable {
    case ja = "자시"    // 23:00-01:00
    case chuk = "축시"  // 01:00-03:00
    case in_ = "인시"   // 03:00-05:00
    case myo = "묘시"   // 05:00-07:00
    case jin = "진시"   // 07:00-09:00
    case sa = "사시"    // 09:00-11:00
    case o = "오시"     // 11:00-13:00
    case mi = "미시"    // 13:00-15:00
    case sin = "신시"   // 15:00-17:00
    case yu = "유시"    // 17:00-19:00
    case sul = "술시"   // 19:00-21:00
    case hae = "해시"   // 21:00-23:00

    var displayName: String { rawValue }

    var timeRange: String {
        switch self {
        case .ja: return "23:00~01:00"
        case .chuk: return "01:00~03:00"
        case .in_: return "03:00~05:00"
        case .myo: return "05:00~07:00"
        case .jin: return "07:00~09:00"
        case .sa: return "09:00~11:00"
        case .o: return "11:00~13:00"
        case .mi: return "13:00~15:00"
        case .sin: return "15:00~17:00"
        case .yu: return "17:00~19:00"
        case .sul: return "19:00~21:00"
        case .hae: return "21:00~23:00"
        }
    }
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case basic
    case standard
    case premium

    var displayName: String {
        switch self {
        case .free: return "무료"
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .premium: return "Premium"
        }
    }

    var monthlyPriceWon: Int {
        switch self {
        case .free: return 0
        case .basic: return AppConfig.basicMonthlyPrice
        case .standard: return AppConfig.standardMonthlyPrice
        case .premium: return AppConfig.premiumMonthlyPrice
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return ["오늘의 운세", "투자 성향 기본 분석", "기초 주식 용어"]
        case .basic:
            return ["주간 운세", "ETF 기초 교육", "복리 계산기"]
        case .standard:
            return ["월간 운세", "중급 투자 교육", "성향별 종목 추천"]
        case .premium:
            return ["연간 운세", "고급 교육 + AI 상담", "맞춤형 포트폴리오 제안"]
        }
    }
}
