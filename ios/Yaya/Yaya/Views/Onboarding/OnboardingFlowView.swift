import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentStep = 0
    @State private var selectedGender: Gender?
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var selectedBirthTime: BirthTime?
    @State private var isLunar = false
    @State private var referralCode = ""
    @State private var showTimePicker = false
    @State private var sajuAnalysis: SajuAnalysis?
    @State private var isLoadingFortune = false
    @State private var isSavingProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: Double(currentStep + 1), total: 4)
                    .tint(.purple)
                    .padding(.horizontal)
                    .padding(.top, 8)

                TabView(selection: $currentStep) {
                    // Step 1: 성별 선택
                    genderSelectionView
                        .tag(0)

                    // Step 2: 생년월일 & 시간
                    birthInfoView
                        .tag(1)

                    // Step 3: 추천인 코드
                    referralCodeView
                        .tag(2)

                    // Step 4: 첫 운세 결과
                    FirstFortuneResultView(
                        sajuAnalysis: sajuAnalysis,
                        isLoading: isLoadingFortune,
                        onFinish: {
                            authViewModel.finishOnboarding()
                        }
                    )
                    .environmentObject(authViewModel)
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
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
                withAnimation { currentStep = 2 }
            } label: {
                Text("다음")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
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

    // MARK: - Step 3: 추천인 코드

    private var referralCodeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("추천인 코드 (선택)")
                .font(.title2)
                .fontWeight(.bold)

            Text("친구에게 받은 추천 코드가 있다면\n입력해주세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("추천인 코드 입력", text: $referralCode)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await completeAndShowFortune() }
                } label: {
                    if isSavingProfile {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.purple)
                            .cornerRadius(12)
                    } else {
                        Text("시작하기")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(isSavingProfile)

                Button {
                    referralCode = ""
                    Task { await completeAndShowFortune() }
                } label: {
                    Text("건너뛰기")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .disabled(isSavingProfile)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Complete & Show Fortune

    private func completeAndShowFortune() async {
        guard let gender = selectedGender else { return }
        isSavingProfile = true

        do {
            // 1. 프로필 저장
            try await authViewModel.saveOnboardingProfile(
                gender: gender,
                birthDate: birthDate,
                birthTime: selectedBirthTime,
                isLunar: isLunar
            )

            // 2. 추천 코드 제출
            if !referralCode.isEmpty {
                _ = await authViewModel.submitReferralCode(referralCode)
            }

            // 3. 운세 결과 화면으로 이동
            isSavingProfile = false
            isLoadingFortune = true
            withAnimation { currentStep = 3 }

            // 4. 사주 분석 (Mock)
            let analysis = try await AIService.shared.analyzeSaju(
                birthDate: birthDate,
                birthTime: selectedBirthTime,
                gender: gender
            )
            sajuAnalysis = analysis
            isLoadingFortune = false

        } catch {
            isSavingProfile = false
            isLoadingFortune = false
            authViewModel.errorMessage = "프로필 저장에 실패했습니다: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthViewModel())
}
