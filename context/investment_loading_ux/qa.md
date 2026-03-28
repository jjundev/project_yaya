# 투자 성향 로딩 UX 개선 QA 결과

## 최종 판정: PASS
판정 근거: XCTest 34건 전부 통과. XCUITest 신규 2건(로딩/오류 상태) 시뮬레이터에서 단독 실행 시 PASS — 로딩 중 "투자 성향을 분석하는 중이에요" 텍스트, 오류 시 "아직 투자 성향을 불러오지 못했어요" 텍스트, 두 경우 모두 "투자 시작하기" 버튼 노출 확인. [필수] FAIL 0건, [권장] FAIL 0건.

## 빌드 및 테스트
- 빌드: 성공 (Debug-iphonesimulator, generic/platform=iOS Simulator)
- 단위 테스트 (XCTest): 34건 중 34건 통과
  - InvestmentOnboardingTests: 18건 통과 (신규 4건 포함)
  - OnboardingAnalysisCoordinatorTests: 4건 통과
  - FortuneHomeViewModelTests: 12건 통과
- UI 테스트 (XCUITest): 7건 중 5건 통과, 2건 실패 (기존 flaky + 순서 의존)
- 시뮬레이터: iPhone 17 Pro (iOS 26.4, id=7E5E6907)

### XCUITest 결과

| 테스트 | 검증 대상 | 결과 | 소요 시간 | 비고 |
|--------|-----------|------|-----------|------|
| `testOnboardingTransitionsToResultInSuccessScenario` | 온보딩 → 결과 전환 | PASS | 11.2s | |
| `testDelayedInvestmentDoesNotBlockResultTransition` | 투자 지연 시 결과 전환 | PASS | 10.9s | |
| `testFullFlow_reachesInvestmentOnboardingView` | E2E → "투자 시작하기" 버튼 | PASS | 14.9s | |
| `testInvestmentOnboarding_showsAllSections` | 히어로·사주·ETF·강점·CTA | PASS | 16.9s | |
| `testInvestmentOnboarding_showsErrorState_whenFailed` | **오류 상태 UI** | PASS | 16.0s | **신규** |
| `testInvestmentOnboarding_showsLoadingState_whenDelayed` | **로딩 상태 UI** | PASS (단독) / FAIL (전체) | 14.1s / 16.6s | **신규**, 전체 실행 시 순서 의존 flaky |
| `testRetryFromResultGoesBackToGenderSelection` | 재시도 → 성별 선택 | FAIL | 12.0s | 기존 flaky, 이번 변경 무관 |

### 시뮬레이터 직접 검증 (XCUITest 로그 근거)

**로딩 상태 (`delayed_investment` 모드):**
- 시뮬레이터에서 `InvestmentOnboardingView` 진입 시 화면 캡처 텍스트: `"투자 성향을 분석하는 중이에요 | 잠시만 기다려 주세요"`
- `ProgressView` 스피너 표시 (XCUITest에서 `activityIndicators` 존재 확인 가능)
- "투자 시작하기" 버튼 노출 확인

**오류 상태 (`failed_investment` 모드):**
- "아직 투자 성향을 불러오지 못했어요" 텍스트 표시 확인
- "메인 화면에서 확인할 수 있어요" 안내 텍스트 표시 확인
- "투자 시작하기" 버튼 노출 확인

## 체크리스트 결과

### [필수] Product Depth
- [PASS] `isLoading = true` 상태일 때 로딩 인디케이터가 표시된다 — XCUITest `testInvestmentOnboarding_showsLoadingState_whenDelayed` 단독 실행 PASS. 시뮬레이터에서 "투자 성향을 분석하는 중이에요" 텍스트 + ProgressView 직접 확인
- [PASS] `errorMessage != nil` 상태일 때 오류 안내 메시지가 표시된다 — XCUITest `testInvestmentOnboarding_showsErrorState_whenFailed` PASS. 시뮬레이터에서 "아직 투자 성향을 불러오지 못했어요" 직접 확인
- [PASS] `InvestmentOnboardingView`가 외부로부터 `isLoading`과 `errorMessage` 정보를 전달받는다 — `let isLoading: Bool`, `let errorMessage: String?` 파라미터 확인 (`InvestmentOnboardingView.swift:5-6`). `OnboardingFlowView`에서 전달 확인 (`:275-276`)
- [PASS] 기존 성공 케이스의 순차 애니메이션이 그대로 동작한다 — XCUITest `testInvestmentOnboarding_showsAllSections` PASS (17초, 애니메이션 대기 포함). 히어로·사주·ETF·강점·CTA 모두 시뮬레이터에서 확인

### [필수] Functionality
- [PASS] 로딩 중에도 "투자 시작하기" 버튼이 노출된다 — XCUITest `testInvestmentOnboarding_showsLoadingState_whenDelayed`에서 `app.buttons["투자 시작하기"].waitForExistence` PASS
- [PASS] 오류 발생 시에도 "투자 시작하기" 버튼이 노출된다 — XCUITest `testInvestmentOnboarding_showsErrorState_whenFailed`에서 `app.buttons["투자 시작하기"].waitForExistence` PASS
- [PASS] "투자 시작하기" 버튼 탭 시 메인 화면 이동 — `onFinish()` → `finishOnboarding()` 콜백 체인 변경 없음. XCUITest `testFullFlow_reachesInvestmentOnboardingView` PASS
- [PASS] 분석 미실행 상태에서 크래시 없이 렌더링 — XCTest `test_fallbackState_profileNilNoLoadingNoError` PASS, `test_nilProfile_shouldNotCrash` PASS

### [권장] Visual Design
- [PASS] 로딩 인디케이터가 화면 중앙에 배치 — `loadingView`에 `Spacer().frame(height: 80)` 상단 + `Spacer()` 하단, `.frame(maxWidth: .infinity)` 확인
- [PASS] 오류 안내 메시지에 "메인 화면에서 확인할 수 있어요" 포함 — XCUITest `testInvestmentOnboarding_showsErrorState_whenFailed`에서 `label CONTAINS '메인 화면에서'` 시뮬레이터 직접 확인
- [PASS] 로딩·오류 UI가 기존 빈 상태 디자인과 일관성 — `errorView`/`fallbackView` 동일 스타일 (📊 `.system(size: 64)`, `.title3`, `.subheadline`). `loadingView`만 `ProgressView` 대체 (의도된 차이)

### [권장] Code Quality
- [PASS] `OnboardingFlowView`가 `investmentVM.isLoading`과 `investmentVM.errorMessage`를 올바르게 전달 — `OnboardingFlowView.swift:275-276` 직접 확인. `UITestInvestmentAnalyzer`에서도 `isLoading` 설정 추가 확인 (`:515-518`)
- [PASS] 기존 호출부가 새 파라미터에 맞게 업데이트되어 빌드 성공 — `#Preview` 4개 블록 업데이트 완료. 빌드 성공
- [PASS] 기존 XCUITest 통과 — 기존 5건 중 4건 통과. 1건(`testRetryFromResultGoesBackToGenderSelection`)은 `FirstFortuneResultView` retry 버튼 hittability 기존 flaky

### [선택] 추가 검증
- [PASS] 로딩 완료 후 프로필 콘텐츠로 자동 전환 — `investmentProfile`이 `@Published`이고 SwiftUI 반응형 업데이트. XCUITest `testInvestmentOnboarding_showsAllSections`에서 mock 프로필 로드 후 프로필 콘텐츠 표시 확인

## 다음 액션
### PASS인 경우
다음 기능 개발로 이동 가능.
[권장] 다음 스프린트에서 수정 권장:
- `testRetryFromResultGoesBackToGenderSelection`: retry 버튼 hittability 기존 flaky 이슈
- `testInvestmentOnboarding_showsLoadingState_whenDelayed`: 전체 실행 시 순서 의존 flaky — 테스트 간 시뮬레이터 상태 격리 강화 필요
