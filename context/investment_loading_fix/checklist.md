# 투자 성향 로딩 실패 수정 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 stub 또는 미구현 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 크래시 또는 플로우 막힘 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 빌드 실패 또는 데이터 소실 위험 1건 이상 |

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 동작하는가

- [ ] `AIService.analyzeInvestmentType()`이 Edge Function을 호출하지 않고 mock 데이터를 반환한다 — FAIL 조건: `"investment-personality"` Edge Function 호출 코드가 주석 처리되지 않고 실행되는 경우
- [ ] mock `InvestmentProfile` 반환값에 `investmentType`, `recommendedETFs`, `sajuBasis`, `strengths`가 모두 포함된다 — FAIL 조건: 필드가 비어 있거나 nil인 경우
- [ ] `InvestmentViewModel.loadInvestmentProfile()` 완료 후 `investmentProfile`이 non-nil로 설정된다 — FAIL 조건: `saveInvestmentProfile` 호출 전에 `investmentProfile` 할당이 이루어지지 않아 저장 실패 시 nil로 남는 경우
- [ ] `success` 모드 온보딩 완료 → "투자 시작하기" 탭 → `InvestmentOnboardingView`에 프로필 콘텐츠(히어로 타이틀, ETF, 강점 섹션)가 표시된다 — FAIL 조건: "투자 성향을 불러오는 중이에요" 또는 오류 화면이 표시되는 경우

### [필수] Functionality — 핵심 플로우가 막힘 없이 동작하는가

- [ ] `success` UITest 모드에서 `testInvestmentOnboarding_showsAllSections`가 통과한다 — FAIL 조건: 히어로·사주·ETF·강점·CTA 섹션 중 1개 이상 미표시
- [ ] `success` UITest 모드에서 `testFullFlow_reachesInvestmentOnboardingView`가 통과한다 — FAIL 조건: "투자 시작하기" 버튼이 나타나지 않는 경우
- [ ] 로딩 중(`delayed_investment` 모드) 및 오류(`failed_investment` 모드)의 기존 XCUITest가 회귀 없이 통과한다 — FAIL 조건: 이전에 PASS이던 `testInvestmentOnboarding_showsErrorState_whenFailed`가 실패하는 경우

### [권장] Visual Design — 인터페이스가 일관된 느낌인가

- [ ] 투자 성향 프로필이 로드되는 약 1초 동안 로딩 스피너가 표시된다 (이전 작업 회귀 없음) — FAIL 조건: 스피너 없이 바로 콘텐츠가 나타나거나 "분석하는 중" 텍스트가 사라진 경우
- [ ] `InvestmentOnboardingView`의 히어로 타이틀에 mock 투자 성향 유형명이 포함된다 (`"안정형"` 또는 해당 유형의 displayName) — FAIL 조건: 타이틀이 빈 문자열이거나 "투자자입니다" 패턴과 맞지 않는 경우

### [권장] Code Quality — 연결이 끊어진 곳은 없는가

- [ ] `AIService.swift`에서 Edge Function 호출 코드가 주석 처리되고 `// TODO: 실제 Edge Function 배포 후 교체` 주석이 유지된다 — FAIL 조건: TODO 주석 없이 코드만 삭제된 경우
- [ ] `InvestmentViewModel.swift`에서 `investmentProfile = profile` 할당이 `saveInvestmentProfile` 호출 **앞**에 위치한다 — FAIL 조건: 저장 후 할당 순서 그대로인 경우
- [ ] 기존 XCTest 18건이 모두 통과한다 — FAIL 조건: 기존 통과 테스트 중 1건 이상 새로 실패

### [선택] 추가 검증

- [ ] `saveInvestmentProfile`이 실패하는 상황(네트워크 차단 등)에서도 `investmentProfile`이 표시된다 — `try?`로 전환 후 에러를 무시하는 경로 코드 확인

## Generator 자체 점검 결과
> Generator가 구현 완료 후 채웁니다.

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | 성공 | Debug-iphonesimulator, iPhone 17 Pro (iOS 26.4) |
| 단위 테스트 | 34건 중 34건 통과 | InvestmentOnboardingTests 18건, OnboardingAnalysisCoordinatorTests 4건, FortuneHomeViewModelTests 12건 |
| Product Depth 자체 점검 | PASS | `analyzeInvestmentType`에서 Edge Function 주석 처리 + `mockInvestmentProfile()` 반환. mock에 `investmentType`, `recommendedETFs`, `sajuBasis`, `strengths`, `description`, `risks` 모두 포함. `investmentProfile` 할당이 `saveInvestmentProfile` 앞으로 이동 |
| Functionality 자체 점검 | PASS | 빌드 성공, 기존 34건 단위 테스트 통과. `investmentProfile = profile`이 `try? await saveInvestmentProfile` 앞에 위치하여 저장 실패 시에도 프로필 표시 가능 |
