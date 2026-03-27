import Foundation
import GoogleSignIn

enum GoogleAuthError: Error {
    case missingIDToken
    case missingAccessToken
    case userCancelled
    case unknown(String)
}

struct GoogleAuthResult {
    let idToken: String
    let accessToken: String
    let rawNonce: String
}

enum GoogleAuthService {

    static func configure() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppConfig.googleClientID)
    }

    @MainActor
    static func signIn(rawNonce: String) async throws -> GoogleAuthResult {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw GoogleAuthError.unknown("루트 뷰 컨트롤러를 찾을 수 없습니다")
        }

        let hashedNonce = AppleSignInNonce.sha256(rawNonce)

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: nil,
                nonce: hashedNonce
            )
        } catch let error as NSError {
            if error.code == GIDSignInError.canceled.rawValue {
                throw GoogleAuthError.userCancelled
            }
            throw GoogleAuthError.unknown(error.localizedDescription)
        }

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleAuthError.missingIDToken
        }

        let accessToken = result.user.accessToken.tokenString

        return GoogleAuthResult(idToken: idToken, accessToken: accessToken, rawNonce: rawNonce)
    }

    @discardableResult
    static func handleOpenURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
