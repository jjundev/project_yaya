import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    let appleSignInHelper = AppleSignInHelper()
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

    // MARK: - Login

    func signInWithKakao() async {
        do {
            errorMessage = nil
            let user = try await supabase.signInWithKakao()
            currentUser = user
            isAuthenticated = true
            needsOnboarding = (user.birthDate == nil)
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // User cancelled — do nothing
        } catch {
            errorMessage = "카카오 로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }

    func handleAppleSignIn() async {
        do {
            errorMessage = nil
            let result = try await appleSignInHelper.signIn()
            let user = try await supabase.signInWithApple(
                idToken: result.idToken,
                nonce: result.nonce
            )
            currentUser = user
            isAuthenticated = true
            needsOnboarding = (user.birthDate == nil)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User cancelled — do nothing
        } catch {
            errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
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

import AuthenticationServices
