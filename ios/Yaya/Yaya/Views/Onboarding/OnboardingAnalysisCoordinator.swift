import Foundation

@MainActor
protocol OnboardingProfileSaving: AnyObject {
    var currentUserId: UUID? { get }
    func saveOnboardingProfile(gender: Gender, birthDate: Date, birthTime: BirthTime?, isLunar: Bool) async throws
}

@MainActor
protocol OnboardingSajuAnalyzing: AnyObject {
    var sajuAnalysis: SajuAnalysis? { get set }
    func loadSajuAnalysis(birthDate: Date, birthTime: BirthTime?, gender: Gender) async
}

@MainActor
protocol OnboardingInvestmentAnalyzing: AnyObject {
    var investmentProfile: InvestmentProfile? { get set }
    func loadInvestmentProfile(userId: UUID, sajuAnalysis: SajuAnalysis) async
}

enum OnboardingAnalysisMode: Equatable {
    case live
    case uiTestSuccess
    case uiTestDelayedInvestment
    case uiTestFailedInvestment
    case uiTestFailedSaju

    var isUITest: Bool {
        self != .live
    }

    static func fromLaunchEnvironment(_ environment: [String: String]) -> OnboardingAnalysisMode {
        guard let rawValue = environment["UITEST_MOCK_ANALYSIS"]?.lowercased() else {
            return .live
        }

        switch rawValue {
        case "1", "true", "success":
            return .uiTestSuccess
        case "delayed_investment", "investment_delay", "delay":
            return .uiTestDelayedInvestment
        case "failed_investment", "investment_failure", "investment_fail":
            return .uiTestFailedInvestment
        case "failed_saju", "saju_failure", "saju_fail":
            return .uiTestFailedSaju
        default:
            return .uiTestSuccess
        }
    }
}

@MainActor
struct OnboardingAnalysisCoordinator {
    struct Input {
        let gender: Gender
        let birthDate: Date
        let birthTime: BirthTime?
        let isLunar: Bool
    }

    struct Dependencies {
        let profileSaver: any OnboardingProfileSaving
        let sajuAnalyzer: any OnboardingSajuAnalyzing
        let investmentAnalyzer: any OnboardingInvestmentAnalyzing
    }

    struct Events {
        let setIsSavingProfile: (Bool) -> Void
        let moveToAnalysisStep: () -> Void
        let setAnalysisFinished: (Bool) -> Void
    }

    struct RetryState {
        var currentStep: Int
        var analysisFinished: Bool
        var showResult: Bool
        var isRetrying: Bool
        var analysisKey: Int
    }

    static func startAnalysis(
        input: Input,
        dependencies: Dependencies,
        events: Events
    ) async {
        events.setIsSavingProfile(true)

        do {
            try await dependencies.profileSaver.saveOnboardingProfile(
                gender: input.gender,
                birthDate: input.birthDate,
                birthTime: input.birthTime,
                isLunar: input.isLunar
            )
        } catch {
            // Ignore profile save failures and continue analysis flow.
        }

        events.setIsSavingProfile(false)
        events.moveToAnalysisStep()

        await dependencies.sajuAnalyzer.loadSajuAnalysis(
            birthDate: input.birthDate,
            birthTime: input.birthTime,
            gender: input.gender
        )

        events.setAnalysisFinished(true)

        if let saju = dependencies.sajuAnalyzer.sajuAnalysis,
           let userId = dependencies.profileSaver.currentUserId {
            Task { @MainActor in
                await dependencies.investmentAnalyzer.loadInvestmentProfile(
                    userId: userId,
                    sajuAnalysis: saju
                )
            }
        }

    }

    static func applyRetryReset(_ state: inout RetryState) {
        state.analysisFinished = false
        state.showResult = false
        state.isRetrying = false
        state.analysisKey += 1
        state.currentStep = 0
    }
}

extension AuthViewModel: OnboardingProfileSaving {
    var currentUserId: UUID? {
        currentUser?.id
    }
}

extension FortuneViewModel: OnboardingSajuAnalyzing {}
extension InvestmentViewModel: OnboardingInvestmentAnalyzing {}
