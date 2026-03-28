import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var loadingProvider: String? = nil

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
                    guard loadingProvider == nil else { return }
                    loadingProvider = "kakao"
                    Task {
                        await authViewModel.signInWithKakao()
                        loadingProvider = nil
                    }
                } label: {
                    HStack {
                        if loadingProvider == "kakao" {
                            ProgressView().tint(.black).scaleEffect(0.8)
                        } else {
                            Image(systemName: "message.fill")
                        }
                        Text("카카오로 시작하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(loadingProvider != nil)

                // 구글 로그인
                Button {
                    guard loadingProvider == nil else { return }
                    loadingProvider = "google"
                    Task {
                        await authViewModel.signInWithGoogle()
                        loadingProvider = nil
                    }
                } label: {
                    HStack {
                        if loadingProvider == "google" {
                            ProgressView().tint(.primary).scaleEffect(0.8)
                        } else {
                            Image(systemName: "g.circle.fill")
                        }
                        Text("Google로 시작하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                }
                .disabled(loadingProvider != nil)

                // Apple 로그인
                SignInWithAppleButton(.signIn) { request in
                    loadingProvider = "apple"
                    let hashedNonce = authViewModel.prepareAppleSignIn()
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = hashedNonce
                } onCompletion: { result in
                    Task {
                        await authViewModel.handleAppleSignIn(result: result)
                        loadingProvider = nil
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(12)
                .disabled(loadingProvider != nil)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Terms
            Text("시작하면 이용약관 및 개인정보 처리방침에 동의합니다")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray2))
                    )
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { authViewModel.errorMessage = nil }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.errorMessage)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
