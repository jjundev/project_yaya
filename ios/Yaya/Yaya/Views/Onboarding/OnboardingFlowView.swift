import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var fortuneVM = FortuneViewModel()
    @StateObject private var investmentVM = InvestmentViewModel()

    @State private var currentStep = 0
    @State private var selectedGender: Gender?
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var selectedBirthTime: BirthTime?
    @State private var isLunar = false
    @State private var showTimePicker = false
    @State private var isSavingProfile = false
    @State private var showResult = false
    @State private var showInvestmentOnboarding = false
    @State private var analysisFinished = false
    @State private var isRetrying = false
    @State private var analysisKey = 0
    @State private var resultTransitionTask: Task<Void, Never>?
    private let analysisMode: OnboardingAnalysisMode

    init(analysisMode: OnboardingAnalysisMode = .live) {
        self.analysisMode = analysisMode
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar (3 steps)
                if currentStep < 2 {
                    ProgressView(value: Double(currentStep + 1), total: 3)
                        .tint(.purple)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                TabView(selection: $currentStep) {
                    // Step 1: 성별 선택
                    genderSelectionView
                        .tag(0)

                    // Step 2: 생년월일 & 시간
                    birthInfoView
                        .tag(1)

                    // Step 3: 분석 중 → 결과
                    analysisAndResultView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: analysisFinished) { _, finished in
                if finished {
                    scheduleResultTransition()
                } else {
                    cancelResultTransition()
                }
            }
            .onDisappear {
                cancelResultTransition()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentStep == 1 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 1: 성별

    private var genderSelectionView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("성별을 선택해주세요")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityIdentifier("onboarding.gender.title")

            Text("사주 분석에 필요한 정보입니다")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Button {
                        selectedGender = gender
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: gender == .male ? "figure.stand" : "figure.stand.dress")
                                .font(.system(size: 48))
                            Text(gender.displayName)
                                .font(.headline)
                        }
                        .frame(width: 140, height: 140)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedGender == gender ? Color.purple.opacity(0.1) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedGender == gender ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(selectedGender == gender ? .purple : .primary)
                    .accessibilityIdentifier("onboarding.gender.\(gender.rawValue)")
                }
            }

            Spacer()

            Button {
                withAnimation { currentStep = 1 }
            } label: {
                Text("다음")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedGender != nil ? Color.purple : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(selectedGender == nil)
            .accessibilityIdentifier("onboarding.next.gender")
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step 2: 생년월일

    private var birthInfoView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("생년월일을 입력해주세요")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityIdentifier("onboarding.birth.title")

            // 양력/음력 토글
            Picker("달력 유형", selection: $isLunar) {
                Text("양력").tag(false)
                Text("음력").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)

            // 날짜 선택
            DatePicker(
                "생년월일",
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ko_KR"))

            // 태어난 시간
            VStack(spacing: 8) {
                Text("태어난 시 (선택)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    showTimePicker.toggle()
                } label: {
                    HStack {
                        Text(selectedBirthTime?.displayName ?? "모름")
                        if let time = selectedBirthTime {
                            Text("(\(time.timeRange))")
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .foregroundColor(.primary)
            }

            Spacer()

            Button {
                Task { await startAnalysis() }
            } label: {
                if isSavingProfile {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.purple)
                        .cornerRadius(12)
                } else {
                    Text("다음")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(isSavingProfile)
            .accessibilityIdentifier("onboarding.next.birth")
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showTimePicker) {
            birthTimePickerSheet
        }
    }

    // MARK: - 시간 선택 시트

    private var birthTimePickerSheet: some View {
        NavigationStack {
            List {
                Button("모름") {
                    selectedBirthTime = nil
                    showTimePicker = false
                }
                .foregroundColor(selectedBirthTime == nil ? .purple : .primary)

                ForEach(BirthTime.allCases, id: \.self) { time in
                    Button {
                        selectedBirthTime = time
                        showTimePicker = false
                    } label: {
                        HStack {
                            Text(time.displayName)
                            Spacer()
                            Text(time.timeRange)
                                .foregroundColor(.secondary)
                            if selectedBirthTime == time {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .foregroundColor(selectedBirthTime == time ? .purple : .primary)
                }
            }
            .navigationTitle("태어난 시 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { showTimePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Step 3: 분석 중 → 결과

    @ViewBuilder
    private var analysisAndResultView: some View {
        if showInvestmentOnboarding {
            InvestmentOnboardingView(
                investmentProfile: investmentVM.investmentProfile,
                onFinish: {
                    authViewModel.finishOnboarding()
                }
            )
        } else if showResult {
            FirstFortuneResultView(
                sajuAnalysis: fortuneVM.sajuAnalysis,
                investmentProfile: investmentVM.investmentProfile,
                analysisKey: analysisKey,
                onFinish: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showInvestmentOnboarding = true
                    }
                },
                onRetry: {
                    // 1. Fade out result screen
                    withAnimation(.easeIn(duration: 0.3)) {
                        isRetrying = true
                    }
                    // 2. After fade-out, reset and go back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        fortuneVM.sajuAnalysis = nil
                        investmentVM.investmentProfile = nil
                        var retryState = OnboardingAnalysisCoordinator.RetryState(
                            currentStep: currentStep,
                            analysisFinished: analysisFinished,
                            showResult: showResult,
                            isRetrying: isRetrying,
                            analysisKey: analysisKey
                        )
                        OnboardingAnalysisCoordinator.applyRetryReset(&retryState)
                        analysisFinished = retryState.analysisFinished
                        showResult = retryState.showResult
                        showInvestmentOnboarding = false
                        isRetrying = retryState.isRetrying
                        analysisKey = retryState.analysisKey
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = retryState.currentStep
                        }
                    }
                }
            )
            .id("result-\(analysisKey)")
            .opacity(isRetrying ? 0 : 1)
        } else {
            AnalysisLoadingView(
                sajuAnalysisComplete: fortuneVM.sajuAnalysis != nil,
                analysisFinished: analysisFinished
            )
            .id("loading-\(analysisKey)")
        }
    }

    // MARK: - Start Analysis

    @MainActor
    private func startAnalysis() async {
        guard let gender = selectedGender else { return }
        cancelResultTransition()
        await OnboardingAnalysisCoordinator.startAnalysis(
            input: .init(
                gender: gender,
                birthDate: birthDate,
                birthTime: selectedBirthTime,
                isLunar: isLunar
            ),
            dependencies: makeAnalysisDependencies(),
            events: .init(
                setIsSavingProfile: { isSavingProfile = $0 },
                moveToAnalysisStep: {
                    withAnimation { currentStep = 2 }
                },
                setAnalysisFinished: { analysisFinished = $0 }
            )
        )
    }

    @MainActor
    private func makeAnalysisDependencies() -> OnboardingAnalysisCoordinator.Dependencies {
        switch analysisMode {
        case .live:
            return .init(
                profileSaver: authViewModel,
                sajuAnalyzer: fortuneVM,
                investmentAnalyzer: investmentVM
            )
        case .uiTestSuccess:
            return .init(
                profileSaver: UITestProfileSaver(authViewModel: authViewModel),
                sajuAnalyzer: UITestSajuAnalyzer(fortuneViewModel: fortuneVM, shouldFail: false),
                investmentAnalyzer: UITestInvestmentAnalyzer(
                    investmentViewModel: investmentVM,
                    delayNanoseconds: 0,
                    shouldFail: false
                )
            )
        case .uiTestDelayedInvestment:
            return .init(
                profileSaver: UITestProfileSaver(authViewModel: authViewModel),
                sajuAnalyzer: UITestSajuAnalyzer(fortuneViewModel: fortuneVM, shouldFail: false),
                investmentAnalyzer: UITestInvestmentAnalyzer(
                    investmentViewModel: investmentVM,
                    delayNanoseconds: 4_000_000_000,
                    shouldFail: false
                )
            )
        case .uiTestFailedInvestment:
            return .init(
                profileSaver: UITestProfileSaver(authViewModel: authViewModel),
                sajuAnalyzer: UITestSajuAnalyzer(fortuneViewModel: fortuneVM, shouldFail: false),
                investmentAnalyzer: UITestInvestmentAnalyzer(
                    investmentViewModel: investmentVM,
                    delayNanoseconds: 0,
                    shouldFail: true
                )
            )
        case .uiTestFailedSaju:
            return .init(
                profileSaver: UITestProfileSaver(authViewModel: authViewModel),
                sajuAnalyzer: UITestSajuAnalyzer(fortuneViewModel: fortuneVM, shouldFail: true),
                investmentAnalyzer: UITestInvestmentAnalyzer(
                    investmentViewModel: investmentVM,
                    delayNanoseconds: 0,
                    shouldFail: false
                )
            )
        }
    }

    @MainActor
    private func scheduleResultTransition() {
        guard !showResult else { return }
        cancelResultTransition()
        resultTransitionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                showResult = true
            }
            resultTransitionTask = nil
        }
    }

    @MainActor
    private func cancelResultTransition() {
        resultTransitionTask?.cancel()
        resultTransitionTask = nil
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthViewModel())
}

@MainActor
private final class UITestProfileSaver: OnboardingProfileSaving {
    private let authViewModel: AuthViewModel
    private let fallbackUserId = UUID()

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    var currentUserId: UUID? {
        authViewModel.currentUser?.id ?? fallbackUserId
    }

    func saveOnboardingProfile(gender: Gender, birthDate: Date, birthTime: BirthTime?, isLunar: Bool) async throws {
        if authViewModel.currentUser == nil {
            authViewModel.currentUser = AppUser(
                id: fallbackUserId,
                email: nil,
                phone: nil,
                nickname: nil,
                gender: nil,
                birthDate: nil,
                birthTime: nil,
                isLunar: false,
                referralCode: nil,
                referredBy: nil,
                referralCount: 0,
                subscriptionTier: .free,
                createdAt: nil,
                updatedAt: nil
            )
        }

        authViewModel.currentUser?.gender = gender
        authViewModel.currentUser?.birthDate = birthDate
        authViewModel.currentUser?.birthTime = birthTime
        authViewModel.currentUser?.isLunar = isLunar
    }
}

@MainActor
private final class UITestSajuAnalyzer: OnboardingSajuAnalyzing {
    private let fortuneViewModel: FortuneViewModel
    private let shouldFail: Bool

    init(fortuneViewModel: FortuneViewModel, shouldFail: Bool) {
        self.fortuneViewModel = fortuneViewModel
        self.shouldFail = shouldFail
    }

    var sajuAnalysis: SajuAnalysis? {
        get { fortuneViewModel.sajuAnalysis }
        set { fortuneViewModel.sajuAnalysis = newValue }
    }

    func loadSajuAnalysis(birthDate: Date, birthTime: BirthTime?, gender: Gender) async {
        if shouldFail {
            fortuneViewModel.sajuAnalysis = nil
            return
        }
        fortuneViewModel.sajuAnalysis = AIService.shared.mockSajuAnalysis(gender: gender)
    }
}

@MainActor
private final class UITestInvestmentAnalyzer: OnboardingInvestmentAnalyzing {
    private let investmentViewModel: InvestmentViewModel
    private let delayNanoseconds: UInt64
    private let shouldFail: Bool

    init(investmentViewModel: InvestmentViewModel, delayNanoseconds: UInt64, shouldFail: Bool) {
        self.investmentViewModel = investmentViewModel
        self.delayNanoseconds = delayNanoseconds
        self.shouldFail = shouldFail
    }

    var investmentProfile: InvestmentProfile? {
        get { investmentViewModel.investmentProfile }
        set { investmentViewModel.investmentProfile = newValue }
    }

    func loadInvestmentProfile(userId: UUID, sajuAnalysis: SajuAnalysis) async {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        if shouldFail {
            investmentViewModel.investmentProfile = nil
            investmentViewModel.errorMessage = "UITest mock investment failure"
            return
        }

        investmentViewModel.errorMessage = nil
        investmentViewModel.investmentProfile = InvestmentProfile(
            id: UUID(),
            userId: userId,
            investmentType: .stable,
            description: "테스트용 투자 성향 결과",
            strengths: ["분산 투자 선호"],
            risks: ["수익 극대화 욕구 부족"],
            recommendedETFs: ["VOO (S&P 500)", "VTI (미국 전체 시장)"],
            sajuBasis: "UI 테스트용 Mock",
            createdAt: Date()
        )
    }
}
