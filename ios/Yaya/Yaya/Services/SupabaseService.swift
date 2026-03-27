import Foundation
import Supabase
import AuthenticationServices

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }

    // MARK: - Auth

    func signInWithKakao(accessToken: String) async throws -> AppUser {
        // Edge Function 응답 모델
        struct KakaoLoginResponse: Decodable {
            let email: String
            let token: String
            let user_id: String
            let kakao_id: String
        }

        // 1. Edge Function 호출 (카카오 토큰 검증 + 유저 생성/조회)
        let response: KakaoLoginResponse = try await client.functions.invoke(
            "kakao-login",
            options: .init(body: ["access_token": accessToken])
        )

        // 2. hashed_token으로 Supabase 세션 생성
        try await client.auth.verifyOTP(
            tokenHash: response.token,
            type: .magiclink
        )

        return try await fetchOrCreateMinimalUser()
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AppUser {
        _ = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        return try await fetchOrCreateMinimalUser()
    }

    func handleAuthCallback(_ url: URL) async throws {
        try await client.auth.session(from: url)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func getCurrentSession() async -> AppUser? {
        do {
            let session = try await client.auth.session
            return try await fetchUserProfile(userId: session.user.id)
        } catch {
            return nil
        }
    }

    // MARK: - User Profile

    func createOrUpdateUserProfile(
        userId: UUID,
        gender: Gender,
        birthDate: Date,
        birthTime: BirthTime?,
        isLunar: Bool
    ) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        struct UserProfileRow: Encodable {
            let id: String
            let gender: String
            let birth_date: String
            let birth_time: String?
            let is_lunar: Bool
        }

        let row = UserProfileRow(
            id: userId.uuidString,
            gender: gender.rawValue,
            birth_date: formatter.string(from: birthDate),
            birth_time: birthTime?.rawValue,
            is_lunar: isLunar
        )

        try await client
            .from("users")
            .upsert(row)
            .execute()
    }

    func getUserProfile(userId: UUID) async throws -> AppUser {
        try await fetchUserProfile(userId: userId)
    }

    // MARK: - Fortune

    func getFortune(userId: UUID, type: FortuneType, date: Date) async throws -> Fortune? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        struct FortuneRow: Decodable {
            let id: UUID
            let user_id: UUID
            let fortune_type: String
            let content: FortuneContent
            let date: String
            let created_at: String
        }

        let rows: [FortuneRow] = try await client
            .from("fortunes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("fortune_type", value: type.rawValue)
            .eq("date", value: formatter.string(from: date))
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { return nil }

        let dateFormatter = ISO8601DateFormatter()
        return Fortune(
            id: row.id,
            userId: row.user_id,
            fortuneType: FortuneType(rawValue: row.fortune_type) ?? .daily,
            content: row.content,
            date: dateFormatter.date(from: row.date) ?? date,
            createdAt: dateFormatter.date(from: row.created_at) ?? Date()
        )
    }

    func saveFortune(_ fortune: Fortune) async throws {
        struct FortuneRow: Encodable {
            let id: String
            let user_id: String
            let fortune_type: String
            let content: FortuneContent
            let date: String
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let row = FortuneRow(
            id: fortune.id.uuidString,
            user_id: fortune.userId.uuidString,
            fortune_type: fortune.fortuneType.rawValue,
            content: fortune.content,
            date: formatter.string(from: fortune.date)
        )

        try await client
            .from("fortunes")
            .upsert(row)
            .execute()
    }

    // MARK: - Investment Profile

    func getInvestmentProfile(userId: UUID) async throws -> InvestmentProfile? {
        struct Row: Decodable {
            let id: UUID
        }

        let rows: [InvestmentProfile] = try await client
            .from("investment_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    func saveInvestmentProfile(_ profile: InvestmentProfile) async throws {
        try await client
            .from("investment_profiles")
            .upsert(profile)
            .execute()
    }

    // MARK: - Referral

    func submitReferralCode(_ code: String, userId: UUID) async throws -> Bool {
        struct ReferrerRow: Decodable {
            let id: UUID
        }

        let referrers: [ReferrerRow] = try await client
            .from("users")
            .select("id")
            .eq("referral_code", value: code)
            .limit(1)
            .execute()
            .value

        guard let referrer = referrers.first else { return false }
        guard referrer.id != userId else { return false }

        struct ReferralInsert: Encodable {
            let referrer_id: String
            let referee_id: String
        }

        try await client
            .from("referrals")
            .insert(ReferralInsert(
                referrer_id: referrer.id.uuidString,
                referee_id: userId.uuidString
            ))
            .execute()

        return true
    }

    func getReferralCount(userId: UUID) async throws -> Int {
        struct UserRow: Decodable {
            let referral_count: Int
        }

        let rows: [UserRow] = try await client
            .from("users")
            .select("referral_count")
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first?.referral_count ?? 0
    }

    // MARK: - Coupons

    func getCoupons(userId: UUID) async throws -> [Coupon] {
        try await client
            .from("coupons")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("issued_at", ascending: false)
            .execute()
            .value
    }

    // MARK: - Edge Functions

    func callEdgeFunction<T: Decodable>(name: String, body: [String: Any]) async throws -> T {
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        return try await client.functions.invoke(
            name,
            options: .init(body: jsonData)
        )
    }

    // MARK: - Private

    private func fetchOrCreateMinimalUser() async throws -> AppUser {
        let session = try await client.auth.session
        let authUser = session.user

        do {
            return try await fetchUserProfile(userId: authUser.id)
        } catch {
            // No profile row yet — return minimal user for onboarding
            return AppUser(
                id: authUser.id,
                email: authUser.email,
                phone: authUser.phone,
                nickname: nil,
                gender: nil,
                birthDate: nil,
                birthTime: nil,
                isLunar: false,
                referralCode: nil,
                referredBy: nil,
                referralCount: 0,
                subscriptionTier: .free,
                createdAt: nil,
                updatedAt: nil
            )
        }
    }

    private func fetchUserProfile(userId: UUID) async throws -> AppUser {
        try await client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }
}
