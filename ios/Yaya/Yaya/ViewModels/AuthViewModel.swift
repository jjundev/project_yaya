import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    var currentNonce: String?
    private let supabase = SupabaseService.shared

    // MARK: - Session

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        if let user = await supabase.getCurrentSession() {
            currentUser = user
            isAuthenticated = true
            needsOnboarding = (user.birthDate == nil)
        } else {
            isAuthenticated = false
        }
    }

    // MARK: - Kakao Login (Native KakaoSDK + Edge Function)

    func signInWithKakao() async {
        do {
            errorMessage = nil
            // 1. KakaoSDK 네이티브 로그인 → access_token 획득
            let accessToken = try await KakaoAuthService.login()
            // 2. Edge Function → Supabase 세션 생성
            let user = try await supabase.signInWithKakao(accessToken: accessToken)
            currentUser = user
            isAuthenticated = true
            needsOnboarding = (user.birthDate == nil)
        } catch KakaoAuthError.userCancelled {
            // 사용자 취소 — 에러 표시 안 함
        } catch {
            errorMessage = "카카오 로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Google Login

    func signInWithGoogle() async {
        do {
            errorMessage = nil
            let rawNonce = AppleSignInNonce.generate()
            let result = try await GoogleAuthService.signIn(rawNonce: rawNonce)
            let user = try await supabase.signInWithGoogle(
                idToken: result.idToken,
                accessToken: result.accessToken,
                nonce: rawNonce
            )
            currentUser = user
            isAuthenticated = true
            needsOnboarding = (user.birthDate == nil)
        } catch GoogleAuthError.userCancelled {
            // 사용자 취소 — 에러 표시 안 함
        } catch {
            errorMessage = "구글 로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Apple Sign In

    func prepareAppleSignIn() -> String {
        let nonce = AppleSignInNonce.generate()
        currentNonce = nonce
        return AppleSignInNonce.sha256(nonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Apple 로그인 정보를 가져올 수 없습니다"
                return
            }

            do {
                errorMessage = nil
                let user = try await supabase.signInWithApple(idToken: idToken, nonce: nonce)
                currentUser = user
                isAuthenticated = true
                needsOnboarding = (user.birthDate == nil)
            } catch {
                errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            }

        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled {
                // User cancelled
            } else {
                errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Onboarding

    func saveOnboardingProfile(gender: Gender, birthDate: Date, birthTime: BirthTime?, isLunar: Bool) async throws {
        guard let userId = currentUser?.id else { return }

        try await supabase.createOrUpdateUserProfile(
            userId: userId,
            gender: gender,
            birthDate: birthDate,
            birthTime: birthTime,
            isLunar: isLunar
        )

        currentUser?.gender = gender
        currentUser?.birthDate = birthDate
        currentUser?.birthTime = birthTime
        currentUser?.isLunar = isLunar
    }

    func submitReferralCode(_ code: String) async -> Bool {
        guard let userId = currentUser?.id else { return false }
        return (try? await supabase.submitReferralCode(code, userId: userId)) ?? false
    }

    func finishOnboarding() {
        needsOnboarding = false
    }

    // MARK: - Logout

    func signOut() async {
        do {
            try await supabase.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "로그아웃에 실패했습니다"
        }
    }
}
