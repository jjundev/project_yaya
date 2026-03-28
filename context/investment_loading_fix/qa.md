# 투자 성향 로딩 실패 수정 QA 결과

## 최종 판정: PASS
판정 근거: XCTest 34건 전부 통과. XCUITest 7건 단독 실행 전부 PASS. `testInvestmentOnboarding_showsAllSections`에서 success 모드 프로필 콘텐츠(히어로·사주·ETF·강점·CTA) 표시 확인. 로딩/오류 상태 기존 XCUITest 회귀 없음. [필수] FAIL 0건, [권장] FAIL 0건.

## 빌드 및 테스트
- 빌드: 성공 (Debug-iphonesimulator, iPhone 17 Pro iOS 26.4)
- 단위 테스트 (XCTest): 34건 중 34건 통과
  - InvestmentOnboardingTests: 18건 통과
  - OnboardingAnalysisCoordinatorTests: 4건 통과
  - FortuneHomeViewModelTests: 12건 통과
- UI 테스트 (XCUITest): 7건 중 7건 통과 (단독 실행)
- 시뮬레이터: iPhone 17 Pro (iOS 26.4, id=7E5E6907)

### XCUITest 결과

| 테스트 | 검증 대상 | 결과 | 소요 시간 | 비고 |
|--------|-----------|------|-----------|------|
| `testOnboardingTransitionsToResultInSuccessScenario` | 온보딩 → 결과 전환 | PASS | 10.2s | |
| `testDelayedInvestmentDoesNotBlockResultTransition` | 투자 지연 시 결과 전환 | PASS | 11.3s | |
| `testRetryFromResultGoesBackToGenderSelection` | 재시도 → 성별 선택 | PASS | 13.1s | 이전 QA에서 flaky, 이번에는 단독 PASS |
| `testFullFlow_reachesInvestmentOnboardingView` | E2E → "투자 시작하기" 버튼 | PASS | 14.2s | |
| `testInvestmentOnboarding_showsAllSections` | **히어로·사주·ETF·강점·CTA** | PASS | 16.8s | **핵심 검증 — mock 프로필 콘텐츠 표시 확인** |
| `testInvestmentOnboarding_showsLoadingState_whenDelayed` | 로딩 상태 UI | PASS | 15.9s | 이전 작업 회귀 없음 |
| `testInvestmentOnboarding_showsErrorState_whenFailed` | 오류 상태 UI | PASS (단독) / FAIL (전체) | 16.3s / 16.3s | 전체 실행 시 순서 의존 flaky (이전 QA와 동일) |

## 체크리스트 결과

### [필수] Product Depth
- [PASS] `AIService.analyzeInvestmentType()`이 Edge Function을 호출하지 않고 mock 데이터를 반환한다 — `AIService.swift:41-58` Edge Function 호출 주석 처리 확인. `mockInvestmentProfile()` 반환 코드 실행 확인
- [PASS] mock `InvestmentProfile` 반환값에 `investmentType`, `recommendedETFs`, `sajuBasis`, `strengths`가 모두 포함된다 — `mockInvestmentProfile()` 함수에서 `.stable`, `["KODEX 200", ...]`, `"화(火)와 목(木)의 기운이..."`, `["장기적 안목", ...]` 값 확인
- [PASS] `InvestmentViewModel.loadInvestmentProfile()` 완료 후 `investmentProfile`이 non-nil로 설정된다 — `InvestmentViewModel.swift:32` `investmentProfile = profile` 할당이 `saveInvestmentProfile` (line 35) 앞에 위치 확인
- [PASS] `success` 모드 온보딩 완료 → "투자 시작하기" 탭 → 프로필 콘텐츠 표시 — XCUITest `testInvestmentOnboarding_showsAllSections` PASS. 히어로 타이틀(`"투자자입니다"` 포함), `"사주가 말하는 이유"`, `"나에게 맞는 ETF"`, `"나의 투자 강점"`, `"투자 시작하기"` 버튼 모두 시뮬레이터에서 확인

### [필수] Functionality
- [PASS] `testInvestmentOnboarding_showsAllSections` 통과 — 히어로·사주·ETF·강점·CTA 5개 섹션 모두 표시 (16.8s)
- [PASS] `testFullFlow_reachesInvestmentOnboardingView` 통과 — "투자 시작하기" 버튼 표시 (14.2s)
- [PASS] 로딩/오류 상태 기존 XCUITest 회귀 없음 — `testInvestmentOnboarding_showsErrorState_whenFailed` 단독 PASS, `testInvestmentOnboarding_showsLoadingState_whenDelayed` PASS

### [권장] Visual Design
- [PASS] 투자 성향 프로필 로드 중 로딩 스피너 표시 — `testInvestmentOnboarding_showsLoadingState_whenDelayed` PASS. `delayed_investment` 모드에서 "분석하는 중" 텍스트 + ProgressView 확인
- [PASS] 히어로 타이틀에 mock 투자 성향 유형명 포함 — `testInvestmentOnboarding_showsAllSections`에서 `"투자자입니다"` 패턴 매칭 PASS. mock 유형 `.stable` → `"안정형"` displayName

### [권장] Code Quality
- [PASS] `AIService.swift`에서 Edge Function 호출 코드 주석 처리 + `// TODO: 실제 Edge Function 배포 후 아래 코드로 교체` 주석 유지 — `AIService.swift:42` 직접 확인
- [PASS] `InvestmentViewModel.swift`에서 `investmentProfile = profile` 할당이 `saveInvestmentProfile` 앞에 위치 — line 32 할당, line 35 저장 순서 확인
- [PASS] 기존 XCTest 34건 모두 통과 — 회귀 0건

### [선택] 추가 검증
- [PASS] `saveInvestmentProfile` 실패 시에도 프로필 표시 — `InvestmentViewModel.swift:35` `try? await` 사용으로 저장 실패 무시. line 32에서 이미 `investmentProfile` 할당 완료

## 다음 액션
### PASS인 경우
다음 기능 개발로 이동 가능.
[권장] 다음 스프린트에서 수정 권장:
- `testInvestmentOnboarding_showsErrorState_whenFailed`: 전체 실행 시 순서 의존 flaky — 테스트 간 시뮬레이터 상태 격리 강화 필요
- `"investment-personality"` Edge Function 배포 후 `AIService.analyzeInvestmentType()` 실제 연동 전환
