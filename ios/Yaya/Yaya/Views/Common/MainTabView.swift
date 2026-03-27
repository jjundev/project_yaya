import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var fortuneVM = FortuneViewModel()
    @StateObject private var investmentVM = InvestmentViewModel()

    var body: some View {
        TabView {
            FortuneHomeView()
                .environmentObject(fortuneVM)
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("운세")
                }

            InvestmentProfileView()
                .environmentObject(investmentVM)
                .environmentObject(fortuneVM)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("투자성향")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("마이페이지")
                }
        }
        .tint(.purple)
    }
}
