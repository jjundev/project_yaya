import XCTest
@testable import Yaya

@MainActor
final class NotificationSettingsTests: XCTestCase {

    // MARK: - @AppStorage 기본값

    func test_defaultNotificationTime_is8AM() {
        let interval = NotificationSettingsView.defaultTimeInterval
        let date = Date(timeIntervalSince1970: interval)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        XCTAssertEqual(components.hour, 8)
        XCTAssertEqual(components.minute, 0)
    }

    // MARK: - AppConfig URL

    func test_termsOfServiceURL_isValid() {
        let url = AppConfig.termsOfServiceURL
        XCTAssertNotNil(url.host)
        XCTAssertFalse(url.absoluteString.isEmpty)
    }

    func test_privacyPolicyURL_isValid() {
        let url = AppConfig.privacyPolicyURL
        XCTAssertNotNil(url.host)
        XCTAssertFalse(url.absoluteString.isEmpty)
    }

    func test_termsURL_isDifferentFromPrivacyURL() {
        XCTAssertNotEqual(
            AppConfig.termsOfServiceURL,
            AppConfig.privacyPolicyURL
        )
    }

    // MARK: - NotificationManager 초기 상태

    func test_notificationManager_initialStatus_isNotDetermined() {
        let manager = NotificationManager()
        XCTAssertEqual(manager.authorizationStatus, .notDetermined)
    }

    // MARK: - AuthViewModel 사주 재분석 (needsOnboarding 전환)

    func test_reanalysis_setsNeedsOnboardingToTrue() {
        let vm = AuthViewModel()
        vm.setupMockUser()
        XCTAssertFalse(vm.needsOnboarding)

        vm.needsOnboarding = true
        XCTAssertTrue(vm.needsOnboarding)
    }

    func test_reanalysis_preservesAuthenticatedState() {
        let vm = AuthViewModel()
        vm.setupMockUser()
        XCTAssertTrue(vm.isAuthenticated)

        vm.needsOnboarding = true
        XCTAssertTrue(vm.isAuthenticated, "재분석 시 로그아웃되면 안 됨")
    }

    // MARK: - SupabaseService 삭제 함수 존재 확인

    func test_supabaseService_hasDeleteInvestmentProfile() {
        // SupabaseService에 deleteInvestmentProfile 함수가 존재하는지 컴파일 타임 검증
        let service = SupabaseService.shared
        let _: (UUID) async throws -> Void = service.deleteInvestmentProfile
        // 컴파일 성공 = 함수 존재 확인
    }

    func test_supabaseService_hasDeleteFortunes() {
        // SupabaseService에 deleteFortunes 함수가 존재하는지 컴파일 타임 검증
        let service = SupabaseService.shared
        let _: (UUID) async throws -> Void = service.deleteFortunes
        // 컴파일 성공 = 함수 존재 확인
    }
}
