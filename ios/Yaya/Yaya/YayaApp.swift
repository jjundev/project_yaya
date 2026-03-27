import SwiftUI

@main
struct YayaApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        KakaoAuthService.initializeSDK()
        GoogleAuthService.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
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
            .task {
                await authViewModel.checkSession()
            }
            .onOpenURL { url in
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
