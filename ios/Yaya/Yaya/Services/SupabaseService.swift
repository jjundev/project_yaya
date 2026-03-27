import Foundation

// Supabase Swift SDK 연동 서비스
// SPM 의존성: https://github.com/supabase/supabase-swift (추가 필요)

final class SupabaseService {
    static let shared = SupabaseService()

    // TODO: Supabase SDK 연동 후 실제 클라이언트로 교체
    // private let client: SupabaseClient

    private init() {
        // client = SupabaseClient(
        //     supabaseURL: URL(string: AppConfig.supabaseURL)!,
        //     supabaseKey: AppConfig.supabaseAnonKey
        // )
    }

    // MARK: - Auth

    func signInWithKakao() async throws -> AppUser {
        // TODO: 카카오 OAuth → Supabase Auth 연동
        fatalError("Not implemented")
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AppUser {
        // TODO: Apple Sign In → Supabase Auth 연동
        fatalError("Not implemented")
    }

    func signOut() async throws {
        // TODO: Supabase Auth signOut
    }

    func getCurrentSession() async -> AppUser? {
        // TODO: 현재 세션 확인
        return nil
    }

    // MARK: - User Profile

    func updateUserProfile(userId: UUID, gender: Gender, birthDate: Date, birthTime: BirthTime?, isLunar: Bool) async throws {
        // TODO: users 테이블 UPDATE
    }

    func getUserProfile(userId: UUID) async throws -> AppUser {
        // TODO: users 테이블 SELECT
        fatalError("Not implemented")
    }

    // MARK: - Fortune

    func getFortune(userId: UUID, type: FortuneType, date: Date) async throws -> Fortune? {
        // TODO: fortunes 테이블에서 캐시된 운세 조회
        return nil
    }

    func saveFortune(_ fortune: Fortune) async throws {
        // TODO: fortunes 테이블에 운세 저장 (캐시)
    }

    // MARK: - Investment Profile

    func getInvestmentProfile(userId: UUID) async throws -> InvestmentProfile? {
        // TODO: investment_profiles 테이블 조회
        return nil
    }

    func saveInvestmentProfile(_ profile: InvestmentProfile) async throws {
        // TODO: investment_profiles 테이블 저장
    }

    // MARK: - Referral

    func submitReferralCode(_ code: String, userId: UUID) async throws -> Bool {
        // TODO: process-referral Edge Function 호출
        return false
    }

    func getReferralCount(userId: UUID) async throws -> Int {
        // TODO: users 테이블에서 referral_count 조회
        return 0
    }

    // MARK: - Coupons

    func getCoupons(userId: UUID) async throws -> [Coupon] {
        // TODO: coupons 테이블 조회
        return []
    }

    // MARK: - Edge Functions

    func callEdgeFunction<T: Decodable>(name: String, body: [String: Any]) async throws -> T {
        // TODO: Supabase Edge Function 호출
        fatalError("Not implemented")
    }
}
