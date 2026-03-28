import SwiftUI

struct FortuneHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var fortuneVM: FortuneViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSubscriptionSheet = false
    @State private var subscriptionPromptTier: SubscriptionTier = .basic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    personalizedHeader

                    if fortuneVM.isLoading && fortuneVM.dailyFortune == nil {
                        loadingView
                    } else if fortuneVM.errorMessage != nil && fortuneVM.dailyFortune == nil {
                        errorView
                    } else {
                        dailyFortuneCard

                        if let saju = fortuneVM.sajuAnalysis {
                            elementInsightCard(saju)
                        }

                        weeklyFortuneBlurCard

                        aiCounselingCTA
                    }
                }
                .padding()
            }
            .navigationTitle("오늘의 운세")
            .refreshable {
                await refreshData()
            }
            .task {
                await loadData()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && fortuneVM.hasDateChanged() {
                    Task { await loadData() }
                }
            }
            .sheet(isPresented: $showSubscriptionSheet) {
                subscriptionPromptSheet
            }
        }
    }

    // MARK: - 개인화 헤더

    private var personalizedHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedToday)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let energySummary = fortuneVM.dailyFortune?.content.energySummary {
                Text(energySummary)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }

    // MARK: - 로딩 상태

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("운세를 분석하고 있어요...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - 에러 상태 + 재시도

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(fortuneVM.errorMessage ?? "운세를 불러오지 못했습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await loadData() }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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

            if let fortune = fortuneVM.dailyFortune {
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

                // 오늘의 조언 (강조)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(fortune.content.advice)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(8)
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

    // MARK: - 오행 에너지 인사이트

    private func elementInsightCard(_ saju: SajuAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오행 에너지")
                .font(.headline)

            // 인사이트 문구 (매일 변경)
            if let insight = fortuneVM.dailyFortune?.content.elementInsight {
                Text(insight)
                    .font(.subheadline)
                    .lineSpacing(4)
                    .foregroundColor(.primary.opacity(0.85))
            }

            // 오행 바 차트
            VStack(alignment: .leading, spacing: 8) {
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

    // MARK: - 주간 운세 블러 미리보기

    private var weeklyFortuneBlurCard: some View {
        let userTier = authViewModel.currentUser?.subscriptionTier ?? .free
        let isUnlocked = userTier != .free

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("주간 운세")
                    .font(.headline)
                Spacer()
                if !isUnlocked {
                    Text("Basic")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
            }

            if isUnlocked, let weekly = fortuneVM.weeklyFortune {
                // 구독자: 전체 내용 표시
                Text(weekly.content.summary)
                    .font(.subheadline)
                    .lineSpacing(4)

                if let detail = weekly.content.detailedAnalysis {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
            } else {
                // 비구독자: 블러 미리보기
                ZStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(fortuneVM.weeklyFortune?.content.summary ?? "이번 주는 전반적으로 상승 기운이 흐르는 한 주입니다. 특히 주 중반에 좋은 소식이 찾아올 수 있어요.")
                            .font(.subheadline)
                            .lineSpacing(4)
                        Text("월요일은 차분하게 시작하되, 화요일부터 에너지가 올라갑니다. 수요일이 이번 주의 하이라이트로...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .blur(radius: 6)

                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        Text("Basic 구독으로 주간 운세를 확인하세요")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Button("구독하기") {
                            subscriptionPromptTier = .basic
                            showSubscriptionSheet = true
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - AI 상담 CTA

    private var aiCounselingCTA: some View {
        Button {
            subscriptionPromptTier = .premium
            showSubscriptionSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.title3)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI 사주 상담")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("나만의 AI 상담사와 1:1 대화")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .purple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }

    // MARK: - 구독 안내 Sheet

    private var subscriptionPromptSheet: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: subscriptionPromptTier == .premium ? "bubble.left.and.text.bubble.right.fill" : "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            Text(subscriptionPromptTier == .premium ? "AI 사주 상담" : "주간 운세")
                .font(.title2)
                .fontWeight(.bold)

            Text(subscriptionPromptTier == .premium
                 ? "Premium 구독으로 나만의 AI 사주 상담사와\n1:1 대화를 시작하세요"
                 : "Basic 구독으로 이번 주 전체 운세 흐름을\n미리 확인하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 8) {
                Text(subscriptionPromptTier.displayName)
                    .font(.headline)
                Text("월 \(subscriptionPromptTier.monthlyPriceWon.formatted())원")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(subscriptionPromptTier.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }

            Spacer()

            Button {
                // TODO: 실제 인앱 구매 연동
                showSubscriptionSheet = false
            } label: {
                Text("구독하기")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Button("나중에") {
                showSubscriptionSheet = false
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(24)
        .presentationDetents([.medium])
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
        await fortuneVM.loadWeeklyFortune(userId: user.id)
    }

    private func refreshData() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        await fortuneVM.loadDailyFortune(userId: userId)
        await fortuneVM.loadWeeklyFortune(userId: userId)
    }
}
