import SwiftUI

struct FortuneHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var fortuneVM: FortuneViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 오늘의 운세 카드
                    dailyFortuneCard

                    // 사주 분석 요약
                    if let saju = fortuneVM.sajuAnalysis {
                        sajuSummaryCard(saju)
                    }

                    // 운세 카테고리 잠금 안내
                    fortuneTierCards
                }
                .padding()
            }
            .navigationTitle("오늘의 운세")
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await fortuneVM.loadDailyFortune(userId: userId)
                }
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - 오늘의 운세 카드

    private var dailyFortuneCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("오늘의 운세")
                    .font(.headline)
                Spacer()
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if fortuneVM.isLoading {
                HStack {
                    Spacer()
                    ProgressView("운세를 분석하고 있어요...")
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if let fortune = fortuneVM.dailyFortune {
                Text(fortune.content.summary)
                    .font(.body)
                    .lineSpacing(4)

                // 운세 점수
                HStack(spacing: 16) {
                    scoreItem(icon: "heart.fill", label: "사랑", score: fortune.content.loveScore, color: .pink)
                    scoreItem(icon: "wonsign.circle.fill", label: "재물", score: fortune.content.moneyScore, color: .green)
                    scoreItem(icon: "heart.text.square.fill", label: "건강", score: fortune.content.healthScore, color: .orange)
                    scoreItem(icon: "briefcase.fill", label: "직장", score: fortune.content.workScore, color: .blue)
                }

                Divider()

                HStack {
                    Label("행운의 숫자: \(fortune.content.luckyNumber)", systemImage: "sparkle")
                    Spacer()
                    Label("행운의 색: \(fortune.content.luckyColor)", systemImage: "paintpalette.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Text("💡 \(fortune.content.advice)")
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(8)
            } else {
                Text("운세를 불러오지 못했습니다")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func scoreItem(icon: String, label: String, score: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= score ? color : Color(.systemGray4))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    // MARK: - 사주 요약

    private func sajuSummaryCard(_ saju: SajuAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("나의 사주 분석")
                .font(.headline)

            Text(saju.summary)
                .font(.subheadline)
                .lineSpacing(4)

            // 오행 그래프
            VStack(alignment: .leading, spacing: 8) {
                Text("오행 비율")
                    .font(.caption)
                    .foregroundColor(.secondary)

                elementBar(label: "목(木)", value: saju.fiveElements.wood, color: .green)
                elementBar(label: "화(火)", value: saju.fiveElements.fire, color: .red)
                elementBar(label: "토(土)", value: saju.fiveElements.earth, color: .brown)
                elementBar(label: "금(金)", value: saju.fiveElements.metal, color: .gray)
                elementBar(label: "수(水)", value: saju.fiveElements.water, color: .blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func elementBar(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .frame(width: 44, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 12)

            Text("\(value)%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    // MARK: - 구독 등급별 운세

    private var fortuneTierCards: some View {
        VStack(spacing: 12) {
            ForEach([FortuneType.weekly, .monthly, .yearly], id: \.self) { type in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(type.requiredTier.displayName) 이상 구독 시 이용 가능")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let user = authViewModel.currentUser,
              let birthDate = user.birthDate,
              let gender = user.gender else { return }

        await fortuneVM.loadSajuAnalysis(
            birthDate: birthDate,
            birthTime: user.birthTime,
            gender: gender
        )

        await fortuneVM.loadDailyFortune(userId: user.id)
    }
}
