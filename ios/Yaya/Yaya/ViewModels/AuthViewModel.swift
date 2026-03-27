import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    @Published var isLoading = true
    @Published var errorMessage: String?

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
        } catch {
            errorMessage = "카카오 로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }

    func signInWithApple(idToken: String, nonce: String) async {
        do {
            errorMessage = nil
            let user = try await supabase.signInWithApple(idToken: idToken, nonce: nonce)
            currentUser = user
            isAuthenticated = true
            needsOnboarding = (user.birthDate == nil)
        } catch {
            errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Onboarding

    func completeOnboarding(gender: Gender, birthDate: Date, birthTime: BirthTime?, isLunar: Bool) async {
        guard let userId = currentUser?.id else { return }

        do {
            try await supabase.updateUserProfile(
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
            needsOnboarding = false
        } catch {
            errorMessage = "프로필 저장에 실패했습니다: \(error.localizedDescription)"
        }
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
