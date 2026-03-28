import SwiftUI

@main
struct YayaApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    private let analysisMode: OnboardingAnalysisMode
    private let isMainTabTest: Bool

    init() {
        analysisMode = OnboardingAnalysisMode.fromLaunchEnvironment(ProcessInfo.processInfo.environment)
        isMainTabTest = ProcessInfo.processInfo.environment["UITEST_MAIN_TAB"] == "1"

        if !analysisMode.isUITest && !isMainTabTest {
            KakaoAuthService.initializeSDK()
            GoogleAuthService.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isMainTabTest {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .onAppear { authViewModel.setupMockUser() }
                } else if analysisMode.isUITest {
                    OnboardingFlowView(analysisMode: analysisMode)
                        .environmentObject(authViewModel)
                } else {
                    if authViewModel.isLoading {
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
            }
            .task {
                guard !analysisMode.isUITest && !isMainTabTest else { return }
                await authViewModel.checkSession()
            }
            .onOpenURL { url in
                guard !analysisMode.isUITest && !isMainTabTest else { return }
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
