import SwiftUI

@main
struct YayaApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    private let isUITest = ProcessInfo.processInfo.environment["UITEST_MOCK_ANALYSIS"] != nil

    init() {
        if !ProcessInfo.processInfo.environment.keys.contains("UITEST_MOCK_ANALYSIS") {
            KakaoAuthService.initializeSDK()
            GoogleAuthService.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isUITest {
                    // UI 테스트 모드: 로그인 우회, 온보딩 직접 진입
                    OnboardingFlowView()
                        .environmentObject(authViewModel)
                } else if authViewModel.isLoading {
                    SplashView()
                } else if authViewModel.isAuthenticated {
                    if authViewModel.needsOnboarding {
                        OnboardingFlowView()
                            .environmentObject(authViewModel)
                    } else {
                        MainTabView()
                            .environmentObject(authViewModel)
                    }
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .task {
                if !isUITest {
                    await authViewModel.checkSession()
                }
            }
            .onOpenURL { url in
                guard !isUITest else { return }
                // 카카오톡 콜백 URL 우선 처리
                if KakaoAuthService.handleOpenURL(url) {
                    return
                }
                // Google 콜백 URL 처리
                if GoogleAuthService.handleOpenURL(url) {
                    return
                }
                // 기존 Supabase 콜백 처리
                Task {
                    try? await SupabaseService.shared.handleAuthCallback(url)
                    await authViewModel.checkSession()
                }
            }
        }
    }
}
