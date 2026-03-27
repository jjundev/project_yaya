import SwiftUI

@main
struct YayaApp: App {
    @StateObject private var authViewModel = AuthViewModel()

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
        }
    }
}
