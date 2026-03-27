import Foundation
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

enum KakaoAuthError: LocalizedError {
    case missingAccessToken
    case userCancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            return "카카오 로그인 토큰을 받지 못했습니다."
        case .userCancelled:
            return nil  // 사용자 취소는 에러 메시지 불필요
        case .unknown(let message):
            return "카카오 로그인 실패: \(message)"
        }
    }
}

enum KakaoAuthService {

    // MARK: - SDK 초기화

    static func initializeSDK() {
        KakaoSDK.initSDK(appKey: AppConfig.kakaoNativeAppKey)
    }

    // MARK: - URL 콜백 처리

    /// KakaoTalk 앱에서 돌아올 때 URL 처리
    @MainActor
    static func handleOpenURL(_ url: URL) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return false
    }

    // MARK: - 로그인

    /// KakaoTalk 앱 또는 웹으로 로그인 후 access_token 반환
    static func login() async throws -> String {
        if UserApi.isKakaoTalkLoginAvailable() {
            return try await loginWithKakaoTalk()
        } else {
            return try await loginWithKakaoAccount()
        }
    }

    // MARK: - Private

    private static func loginWithKakaoTalk() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        if isUserCancelled(error) {
                            continuation.resume(throwing: KakaoAuthError.userCancelled)
                        } else {
                            continuation.resume(throwing: KakaoAuthError.unknown(error.localizedDescription))
                        }
                        return
                    }
                    guard let accessToken = oauthToken?.accessToken else {
                        continuation.resume(throwing: KakaoAuthError.missingAccessToken)
                        return
                    }
                    continuation.resume(returning: accessToken)
                }
            }
        }
    }

    private static func loginWithKakaoAccount() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        if isUserCancelled(error) {
                            continuation.resume(throwing: KakaoAuthError.userCancelled)
                        } else {
                            continuation.resume(throwing: KakaoAuthError.unknown(error.localizedDescription))
                        }
                        return
                    }
                    guard let accessToken = oauthToken?.accessToken else {
                        continuation.resume(throwing: KakaoAuthError.missingAccessToken)
                        return
                    }
                    continuation.resume(returning: accessToken)
                }
            }
        }
    }

    /// KakaoSDK 에러가 사용자 취소인지 확인
    private static func isUserCancelled(_ error: Error) -> Bool {
        // SdkError.ClientFailed with reason .Cancelled
        let errorString = "\(error)"
        return errorString.contains("cancelled") || errorString.contains("Cancelled")
    }
}
