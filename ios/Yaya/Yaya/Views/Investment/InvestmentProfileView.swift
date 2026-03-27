import SwiftUI

struct InvestmentProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var investmentVM: InvestmentViewModel
    @EnvironmentObject var fortuneVM: FortuneViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if investmentVM.isLoading {
                        ProgressView("투자 성향을 분석하고 있어요...")
                            .padding(.top, 100)
                    } else if let profile = investmentVM.investmentProfile {
                        profileCard(profile)
                        recommendedETFsCard(profile)
                        compoundCalculatorCard
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("투자 성향")
            .task {
                await loadProfile()
            }
        }
    }

    // MARK: - 투자 성향 카드

    private func profileCard(_ profile: InvestmentProfile) -> some View {
        VStack(spacing: 16) {
            // 투자 유형 헤더
            VStack(spacing: 8) {
                Text(profile.investmentType.emoji)
                    .font(.system(size: 60))

                Text("당신은 \(profile.investmentType.displayName)입니다")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(profile.investmentType.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)

            Divider()

            // 상세 설명
            Text(profile.description)
                .font(.body)
                .lineSpacing(4)

            // 사주 근거
            VStack(alignment: .leading, spacing: 8) {
                Label("사주 분석 근거", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(profile.sajuBasis)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.06))
                    .cornerRadius(8)
            }

            // 강점 & 리스크
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("강점", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    ForEach(profile.strengths, id: \.self) { strength in
                        Text("• \(strength)")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Label("주의점", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    ForEach(profile.risks, id: \.self) { risk in
                        Text("• \(risk)")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - 추천 ETF

    private func recommendedETFsCard(_ profile: InvestmentProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("추천 ETF")
                .font(.headline)

            Text("사주 기반 \(profile.investmentType.displayName)에 적합한 ETF")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(profile.recommendedETFs, id: \.self) { etf in
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.purple)
                        .frame(width: 32)
                    Text(etf)
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - 복리 계산기

    private var compoundCalculatorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("복리 계산기")
                .font(.headline)

            Text("VOO(S&P 500)에 1,000만원을 투자하면?")
                .font(.caption)
                .foregroundColor(.secondary)

            let result10 = investmentVM.calculateCompoundInterest(
                principal: 10_000_000, annualRate: 0.10, years: 10
            )
            let result20 = investmentVM.calculateCompoundInterest(
                principal: 10_000_000, annualRate: 0.10, years: 20
            )

            HStack(spacing: 16) {
                resultBox(years: 10, result: result10)
                resultBox(years: 20, result: result20)
            }

            Text("* 연평균 수익률 10% 기준, 세금 22% 적용")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func resultBox(years: Int, result: CompoundResult) -> some View {
        VStack(spacing: 8) {
            Text("\(years)년 후")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(result.formattedNetAmount)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            Text("세후 수익")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("사주 분석을 먼저 진행해주세요")
                .font(.headline)
            Text("운세 탭에서 사주 분석을 완료하면\n투자 성향을 확인할 수 있어요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }

    // MARK: - Data Loading

    private func loadProfile() async {
        guard let user = authViewModel.currentUser,
              let saju = fortuneVM.sajuAnalysis else { return }

        await investmentVM.loadInvestmentProfile(userId: user.id, sajuAnalysis: saju)
    }
}
