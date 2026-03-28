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
            .accessibilityIdentifier("gender_next")
            .disabled(selectedGender == nil)
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
            .accessibilityIdentifier("birth_next")
            .disabled(isSavingProfile)
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
                        analysisFinished = false
                        showResult = false
                        showInvestmentOnboarding = false
                        isRetrying = false
                        analysisKey += 1
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 0
                        }
                    }
                }
            )
            .id(analysisKey)
            .opacity(isRetrying ? 0 : 1)
        } else {
            AnalysisLoadingView(
                sajuAnalysisComplete: fortuneVM.sajuAnalysis != nil,
                analysisFinished: analysisFinished
            )
            .id(analysisKey)
        }
    }

    // MARK: - Start Analysis

    private var isUITestMode: Bool {
        ProcessInfo.processInfo.environment["UITEST_MOCK_ANALYSIS"] != nil
    }

    private func startAnalysis() async {
        guard let gender = selectedGender else { return }

        if isUITestMode {
            await startMockAnalysis(gender: gender)
            return
        }

        isSavingProfile = true

        // 1. 프로필 저장 (실패해도 계속 진행)
        do {
            try await authViewModel.saveOnboardingProfile(
                gender: gender,
                birthDate: birthDate,
                birthTime: selectedBirthTime,
                isLunar: isLunar
            )
        } catch {
            // 프로필 저장 실패는 무시하고 분석 진행
        }

        isSavingProfile = false

        // 2. 분석 화면으로 이동
        withAnimation { currentStep = 2 }

        // 3. 사주 분석
        await fortuneVM.loadSajuAnalysis(
            birthDate: birthDate,
            birthTime: selectedBirthTime,
            gender: gender
        )

        // 4. 투자 성향 분석 (실패해도 계속 진행)
        if let saju = fortuneVM.sajuAnalysis,
           let userId = authViewModel.currentUser?.id {
            await investmentVM.loadInvestmentProfile(
                userId: userId,
                sajuAnalysis: saju
            )
        }

        // 5. 모든 분석 완료 (성공/실패 무관)
        analysisFinished = true

        // 6. 로딩 애니메이션 step3 완료 대기 후 결과 화면 전환
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        withAnimation(.easeInOut(duration: 0.4)) {
            showResult = true
        }
    }

    // MARK: - Mock Analysis (UI 테스트 전용)

    private func startMockAnalysis(gender: Gender) async {
        // 분석 화면으로 즉시 이동
        withAnimation { currentStep = 2 }

        // Mock 사주 분석 데이터
        fortuneVM.sajuAnalysis = SajuAnalysis(
            summary: "테스트 사주 요약",
            personality: "결단력 있고 추진력이 강한 성격",
            strengths: ["빠른 결단력", "높은 리스크 감수 능력", "시장 변화에 민감한 직관"],
            weaknesses: ["감정적 판단 위험"],
            wealthFortune: "재물운이 좋습니다",
            relationships: "대인관계가 원만합니다",
            career: "사업 적성이 높습니다",
            fiveElements: FiveElements(wood: 30, fire: 35, earth: 15, metal: 10, water: 10)
        )

        // Mock 투자 프로필
        let mockType: InvestmentType = {
            if let typeStr = ProcessInfo.processInfo.environment["UITEST_INVESTMENT_TYPE"],
               let type = InvestmentType(rawValue: typeStr) {
                return type
            }
            return .aggressive
        }()

        investmentVM.investmentProfile = InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: mockType,
            description: mockType.shortDescription,
            strengths: ["빠른 결단력", "높은 리스크 감수 능력", "시장 변화에 민감한 직관"],
            risks: ["감정적 매수·매도 위험", "단기 손실에 과민 반응 가능"],
            recommendedETFs: mockType.recommendedETFs,
            sajuBasis: "사주에서 강한 화(火) 기운은 열정과 추진력을 의미하며, 이는 빠른 판단과 과감한 투자 결정으로 이어집니다.",
            createdAt: Date()
        )

        analysisFinished = true
        showResult = true
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthViewModel())
}
