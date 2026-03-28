import SwiftUI

struct InvestmentOnboardingView: View {
    let investmentProfile: InvestmentProfile?
    let onFinish: () -> Void

    @State private var showHero = false
    @State private var showBasis = false
    @State private var showETFs = false
    @State private var showStrengths = false
    @State private var showRisks = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile = investmentProfile {
                        profileContent(profile)
                    } else {
                        emptyView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }

            // Fixed bottom CTA
            Button {
                onFinish()
            } label: {
                Text("투자 시작하기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
            )
            .opacity(showButton ? 1 : 0)
        }
        .task {
            let ns: UInt64 = 300_000_000
            withAnimation(.easeOut(duration: 0.4)) { showHero = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showBasis = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showETFs = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showStrengths = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showRisks = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showButton = true }
        }
    }

    // MARK: - Accent Color

    private var accentColor: Color {
        guard let type = investmentProfile?.investmentType else { return .purple }
        switch type {
        case .aggressive: return Color(red: 0.90, green: 0.30, blue: 0.15)
        case .stable:     return Color(red: 0.20, green: 0.47, blue: 0.80)
        case .value:      return Color(red: 0.24, green: 0.24, blue: 0.55)
        case .growth:     return Color(red: 0.50, green: 0.25, blue: 0.80)
        }
    }

    private var heroBackground: Color {
        accentColor.opacity(0.08)
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: InvestmentProfile) -> some View {
        VStack(spacing: 20) {
            heroSection(profile)
                .modifier(FadeSlideInInvestment(show: showHero))

            if !profile.sajuBasis.isEmpty {
                basisSection(profile.sajuBasis)
                    .modifier(FadeSlideInInvestment(show: showBasis))
            }

            etfSection(profile)
                .modifier(FadeSlideInInvestment(show: showETFs))

            strengthsSection(profile.strengths)
                .modifier(FadeSlideInInvestment(show: showStrengths))

            if !profile.risks.isEmpty {
                risksSection(profile.risks)
                    .modifier(FadeSlideInInvestment(show: showRisks))
            }
        }
    }

    // MARK: - Hero Section

    private func heroSection(_ profile: InvestmentProfile) -> some View {
        VStack(spacing: 12) {
            Text(profile.investmentType.emoji)
                .font(.system(size: 64))
                .padding(.top, 8)

            Text("당신은 \(profile.investmentType.displayName) 투자자입니다")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accentColor)
                .multilineTextAlignment(.center)

            Text(profile.description.isEmpty ? profile.investmentType.shortDescription : profile.description)
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(heroBackground)
        )
    }

    // MARK: - Basis Section

    private func basisSection(_ basis: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("사주가 말하는 이유")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accentColor)

            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.6))
                    .frame(width: 3)

                Text(basis)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.label))
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - ETF Section

    private func etfSection(_ profile: InvestmentProfile) -> some View {
        let etfs = profile.recommendedETFs.isEmpty
            ? profile.investmentType.recommendedETFs
            : profile.recommendedETFs
        let displayETFs = Array(etfs.prefix(5))

        return VStack(alignment: .leading, spacing: 12) {
            Text("나에게 맞는 ETF")
                .font(.system(size: 15, weight: .bold))

            VStack(spacing: 8) {
                ForEach(displayETFs, id: \.self) { etf in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(displayETFs.firstIndex(of: etf).map { $0 + 1 } ?? 1))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(accentColor)
                            )

                        Text(etf)
                            .font(.system(size: 14))
                            .foregroundColor(Color(.label))

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Strengths Section

    private func strengthsSection(_ strengths: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("나의 투자 강점")
                .font(.system(size: 15, weight: .bold))

            ForEach(strengths.prefix(3), id: \.self) { strength in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(accentColor)
                    Text(strength)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                        .lineSpacing(3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Risks Section

    private func risksSection(_ risks: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("주의할 점")
                .font(.system(size: 15, weight: .bold))

            ForEach(risks.prefix(2), id: \.self) { risk in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.systemOrange))
                    Text(risk)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                        .lineSpacing(3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)

            Text("📊")
                .font(.system(size: 64))

            Text("투자 성향을 불러오는 중이에요")
                .font(.title3)
                .fontWeight(.medium)

            Text("메인 화면에서 확인할 수 있어요")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            showButton = true
        }
    }
}

// MARK: - FadeSlideIn Modifier

private struct FadeSlideInInvestment: ViewModifier {
    let show: Bool

    func body(content: Content) -> some View {
        content
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 16)
    }
}

// MARK: - Preview

#Preview("공격형") {
    InvestmentOnboardingView(
        investmentProfile: InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .aggressive,
            description: "강한 화(火) 기운이 도전 정신과 추진력을 나타냅니다",
            strengths: ["빠른 결단력", "높은 리스크 감수 능력", "시장 변화에 민감한 직관"],
            risks: ["감정적 매수·매도 위험", "단기 손실에 과민 반응 가능"],
            recommendedETFs: ["QQQ (나스닥 100)", "TQQQ (나스닥 3배 레버리지)", "ARKK (혁신 기업)"],
            sajuBasis: "사주에서 강한 화(火) 기운은 열정과 추진력을 의미하며, 이는 빠른 판단과 과감한 투자 결정으로 이어집니다.",
            createdAt: Date()
        ),
        onFinish: {}
    )
}

#Preview("안정형") {
    InvestmentOnboardingView(
        investmentProfile: InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .stable,
            description: "꾸준하고 안정적인 수익을 추구하는 타입",
            strengths: ["감정에 흔들리지 않는 냉정함", "장기 관점 유지", "리스크 관리 능력"],
            risks: ["시장 기회를 놓칠 수 있음", "수익률이 공격형보다 낮을 수 있음"],
            recommendedETFs: ["VOO (S&P 500)", "VTI (미국 전체 시장)", "BND (채권)"],
            sajuBasis: "사주에서 강한 수(水) 기운은 인내와 침착함을 나타내며, 장기적 안목으로 안정을 추구하는 성향과 연결됩니다.",
            createdAt: Date()
        ),
        onFinish: {}
    )
}
