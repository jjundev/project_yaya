import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo & Title
            VStack(spacing: 16) {
                Text("야")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("사주로 알아보는 나의 투자 성향")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("생년월일과 태어난 시로\n나만의 운세와 투자 스타일을 확인하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            Spacer()

            // Login Buttons
            VStack(spacing: 12) {
                // 카카오 로그인
                Button {
                    Task { await authViewModel.signInWithKakao() }
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("카카오로 시작하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }

                // Apple 로그인
                SignInWithAppleButton(.signIn) { request in
                    let hashedNonce = authViewModel.prepareAppleSignIn()
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = hashedNonce
                } onCompletion: { result in
                    Task {
                        await authViewModel.handleAppleSignIn(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Error Message
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
            }

            // Terms
            Text("시작하면 이용약관 및 개인정보 처리방침에 동의합니다")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
