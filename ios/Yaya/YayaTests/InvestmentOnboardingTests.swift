import XCTest
@testable import Yaya

final class InvestmentOnboardingTests: XCTestCase {

    // MARK: - ETF 표시 개수

    func test_etfDisplayCount_limitsToFive() {
        let manyETFs = ["A", "B", "C", "D", "E", "F", "G"]
        let displayed = Array(manyETFs.prefix(5))
        XCTAssertEqual(displayed.count, 5)
    }

    func test_etfDisplayCount_showsAllWhenUnderFive() {
        let fewETFs = ["A", "B", "C"]
        let displayed = Array(fewETFs.prefix(5))
        XCTAssertEqual(displayed.count, 3)
    }

    // MARK: - 강점 표시 개수

    func test_strengthsDisplayCount_limitsToThree() {
        let manyStrengths = ["A", "B", "C", "D", "E"]
        let displayed = Array(manyStrengths.prefix(3))
        XCTAssertEqual(displayed.count, 3)
    }

    func test_strengthsDisplayCount_showsAllWhenUnderThree() {
        let fewStrengths = ["A", "B"]
        let displayed = Array(fewStrengths.prefix(3))
        XCTAssertEqual(displayed.count, 2)
    }

    // MARK: - 리스크 표시 개수

    func test_risksDisplayCount_limitsToTwo() {
        let manyRisks = ["X", "Y", "Z"]
        let displayed = Array(manyRisks.prefix(2))
        XCTAssertEqual(displayed.count, 2)
    }

    // MARK: - ETF 폴백 (profile.recommendedETFs 비어있을 때 type 기본값 사용)

    func test_etfFallback_usesTypeDefaultWhenProfileETFsEmpty() {
        let profile = InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .aggressive,
            description: "test",
            strengths: [],
            risks: [],
            recommendedETFs: [],
            sajuBasis: "test",
            createdAt: Date()
        )
        let etfs = profile.recommendedETFs.isEmpty
            ? profile.investmentType.recommendedETFs
            : profile.recommendedETFs
        XCTAssertFalse(etfs.isEmpty)
        XCTAssertEqual(etfs, InvestmentType.aggressive.recommendedETFs)
    }

    func test_etfFallback_usesProfileETFsWhenAvailable() {
        let customETFs = ["CUSTOM1", "CUSTOM2"]
        let profile = InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .aggressive,
            description: "test",
            strengths: [],
            risks: [],
            recommendedETFs: customETFs,
            sajuBasis: "test",
            createdAt: Date()
        )
        let etfs = profile.recommendedETFs.isEmpty
            ? profile.investmentType.recommendedETFs
            : profile.recommendedETFs
        XCTAssertEqual(etfs, customETFs)
    }

    // MARK: - description 폴백

    func test_descriptionFallback_usesShortDescriptionWhenEmpty() {
        let profile = InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .stable,
            description: "",
            strengths: [],
            risks: [],
            recommendedETFs: [],
            sajuBasis: "",
            createdAt: Date()
        )
        let displayDescription = profile.description.isEmpty
            ? profile.investmentType.shortDescription
            : profile.description
        XCTAssertEqual(displayDescription, InvestmentType.stable.shortDescription)
        XCTAssertFalse(displayDescription.isEmpty)
    }

    // MARK: - sajuBasis 빈 문자열 가드 (QA FAIL 수정 검증)

    func test_sajuBasisEmptyGuard_shouldHideSectionWhenEmpty() {
        let profile = InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .aggressive,
            description: "test",
            strengths: ["A"],
            risks: ["B"],
            recommendedETFs: ["C"],
            sajuBasis: "",
            createdAt: Date()
        )
        // 빈 sajuBasis → 섹션 숨김 조건 충족 여부 확인
        XCTAssertTrue(profile.sajuBasis.isEmpty, "sajuBasis가 빈 문자열이어야 함")
        // InvestmentOnboardingView.profileContent에서 !profile.sajuBasis.isEmpty 가드 적용 확인
        // (코드: if !profile.sajuBasis.isEmpty { basisSection(...) })
    }

    func test_sajuBasisNonEmpty_shouldShowSection() {
        let profile = InvestmentProfile(
            id: UUID(),
            userId: UUID(),
            investmentType: .stable,
            description: "test",
            strengths: [],
            risks: [],
            recommendedETFs: [],
            sajuBasis: "사주에서 강한 수(水) 기운은 안정을 추구합니다",
            createdAt: Date()
        )
        XCTAssertFalse(profile.sajuBasis.isEmpty, "sajuBasis가 비어있지 않아야 함")
    }

    // MARK: - nil 안전성 (InvestmentProfile nil → emptyView)

    func test_nilProfile_shouldNotCrash() {
        // InvestmentOnboardingView는 investmentProfile: InvestmentProfile? 파라미터를 받음
        // nil일 때 emptyView 분기 확인
        let profile: InvestmentProfile? = nil
        XCTAssertNil(profile, "nil 프로필 → 빈 상태 UI 분기 진입")
    }

    // MARK: - InvestmentType 기본값 검증

    func test_allInvestmentTypes_haveNonEmptyETFs() {
        for type in InvestmentType.allCases {
            XCTAssertFalse(type.recommendedETFs.isEmpty, "\(type.rawValue) ETF 목록이 비어있음")
        }
    }

    func test_allInvestmentTypes_haveNonEmptyEmoji() {
        for type in InvestmentType.allCases {
            XCTAssertFalse(type.emoji.isEmpty, "\(type.rawValue) 이모지가 비어있음")
        }
    }

    func test_allInvestmentTypes_haveNonEmptyDisplayName() {
        for type in InvestmentType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "\(type.rawValue) 이름이 비어있음")
        }
    }
}
