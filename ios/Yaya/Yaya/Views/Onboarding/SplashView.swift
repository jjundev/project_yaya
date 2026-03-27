import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0
    @State private var scale = 0.8

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.purple.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("야")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("당신의 사주로 알아보는 투자 성향")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView()
                    .padding(.top, 40)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
