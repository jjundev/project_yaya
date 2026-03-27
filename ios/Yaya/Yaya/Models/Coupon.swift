import Foundation

struct Coupon: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let amountWon: Int
    let status: CouponStatus
    let issuedAt: Date
    let expiresAt: Date
    let usedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amountWon = "amount_won"
        case status
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
        case usedAt = "used_at"
    }
}

enum CouponStatus: String, Codable {
    case active
    case used
    case expired

    var displayName: String {
        switch self {
        case .active: return "사용 가능"
        case .used: return "사용 완료"
        case .expired: return "기간 만료"
        }
    }
}
