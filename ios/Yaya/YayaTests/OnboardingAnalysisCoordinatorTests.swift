import XCTest
@testable import Yaya

@MainActor
final class OnboardingAnalysisCoordinatorTests: XCTestCase {
    func testDelayedInvestmentDoesNotBlockAnalysisCompletion() async {
        let profileSaver = MockProfileSaver(userId: UUID())
        let sajuAnalyzer = MockSajuAnalyzer(result: AIService.shared.mockSajuAnalysis(gender: .female))
        let investmentAnalyzer = MockInvestmentAnalyzer(delayNanoseconds: 400_000_000, shouldFail: false)

        var analysisFinished = false
        var investmentCompletedWhenAnalysisFinished = false

        await OnboardingAnalysisCoordinator.startAnalysis(
            input: .init(
                gender: .female,
                birthDate: Date(),
                birthTime: .o,
                isLunar: false
            ),
            dependencies: .init(
                profileSaver: profileSaver,
                sajuAnalyzer: sajuAnalyzer,
                investmentAnalyzer: investmentAnalyzer
            ),
            events: .init(
                setIsSavingProfile: { _ in },
                moveToAnalysisStep: {},
                setAnalysisFinished: { value in
                    analysisFinished = value
                    investmentCompletedWhenAnalysisFinished = investmentAnalyzer.didComplete
                }
            )
        )

        XCTAssertTrue(analysisFinished)
        XCTAssertFalse(investmentCompletedWhenAnalysisFinished)
        XCTAssertFalse(investmentAnalyzer.didComplete)

        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertTrue(investmentAnalyzer.didComplete)
    }

    func testInvestmentFailureStillShowsResult() async {
        let profileSaver = MockProfileSaver(userId: UUID())
        let sajuAnalyzer = MockSajuAnalyzer(result: AIService.shared.mockSajuAnalysis(gender: .male))
        let investmentAnalyzer = MockInvestmentAnalyzer(delayNanoseconds: 0, shouldFail: true)

        var analysisFinished = false
        var didReturn = false

        await OnboardingAnalysisCoordinator.startAnalysis(
            input: .init(
                gender: .male,
                birthDate: Date(),
                birthTime: nil,
                isLunar: false
            ),
            dependencies: .init(
                profileSaver: profileSaver,
                sajuAnalyzer: sajuAnalyzer,
                investmentAnalyzer: investmentAnalyzer
            ),
            events: .init(
                setIsSavingProfile: { _ in },
                moveToAnalysisStep: {},
                setAnalysisFinished: { analysisFinished = $0 }
            )
        )
        didReturn = true

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(didReturn)
        XCTAssertTrue(analysisFinished)
        XCTAssertEqual(investmentAnalyzer.callCount, 1)
        XCTAssertTrue(investmentAnalyzer.didFail)
    }

    func testSajuFailureStillTransitionsToResultAndSkipsInvestment() async {
        let profileSaver = MockProfileSaver(userId: UUID())
        let sajuAnalyzer = MockSajuAnalyzer(result: nil)
        let investmentAnalyzer = MockInvestmentAnalyzer(delayNanoseconds: 0, shouldFail: false)

        var analysisFinished = false
        var didReturn = false

        await OnboardingAnalysisCoordinator.startAnalysis(
            input: .init(
                gender: .female,
                birthDate: Date(),
                birthTime: .jin,
                isLunar: true
            ),
            dependencies: .init(
                profileSaver: profileSaver,
                sajuAnalyzer: sajuAnalyzer,
                investmentAnalyzer: investmentAnalyzer
            ),
            events: .init(
                setIsSavingProfile: { _ in },
                moveToAnalysisStep: {},
                setAnalysisFinished: { analysisFinished = $0 }
            )
        )
        didReturn = true

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(didReturn)
        XCTAssertTrue(analysisFinished)
        XCTAssertEqual(investmentAnalyzer.callCount, 0)
    }

    func testRetryResetResetsFlagsAndIncrementsKey() {
        var state = OnboardingAnalysisCoordinator.RetryState(
            currentStep: 2,
            analysisFinished: true,
            showResult: true,
            isRetrying: true,
            analysisKey: 7
        )

        OnboardingAnalysisCoordinator.applyRetryReset(&state)

        XCTAssertEqual(state.currentStep, 0)
        XCTAssertFalse(state.analysisFinished)
        XCTAssertFalse(state.showResult)
        XCTAssertFalse(state.isRetrying)
        XCTAssertEqual(state.analysisKey, 8)
    }
}

@MainActor
private final class MockProfileSaver: OnboardingProfileSaving {
    let currentUserId: UUID?

    init(userId: UUID?) {
        self.currentUserId = userId
    }

    func saveOnboardingProfile(gender: Gender, birthDate: Date, birthTime: BirthTime?, isLunar: Bool) async throws {
        _ = gender
        _ = birthDate
        _ = birthTime
        _ = isLunar
    }
}

@MainActor
private final class MockSajuAnalyzer: OnboardingSajuAnalyzing {
    var sajuAnalysis: SajuAnalysis?
    private let result: SajuAnalysis?

    init(result: SajuAnalysis?) {
        self.result = result
    }

    func loadSajuAnalysis(birthDate: Date, birthTime: BirthTime?, gender: Gender) async {
        _ = birthDate
        _ = birthTime
        _ = gender
        sajuAnalysis = result
    }
}

@MainActor
private final class MockInvestmentAnalyzer: OnboardingInvestmentAnalyzing {
    var investmentProfile: InvestmentProfile?
    private let delayNanoseconds: UInt64
    private let shouldFail: Bool

    private(set) var callCount = 0
    private(set) var didComplete = false
    private(set) var didFail = false

    init(delayNanoseconds: UInt64, shouldFail: Bool) {
        self.delayNanoseconds = delayNanoseconds
        self.shouldFail = shouldFail
    }

    func loadInvestmentProfile(userId: UUID, sajuAnalysis: SajuAnalysis) async {
        _ = userId
        _ = sajuAnalysis
        callCount += 1

        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        if shouldFail {
            didFail = true
            didComplete = true
            return
        }

        investmentProfile = InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .stable,
            description: "mock",
            strengths: [],
            risks: [],
            recommendedETFs: [],
            sajuBasis: "mock",
            createdAt: Date()
        )
        didComplete = true
    }
}
