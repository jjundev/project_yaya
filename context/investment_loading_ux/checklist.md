# 투자 성향 로딩 UX 개선 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 stub 또는 미구현 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 크래시 또는 플로우 막힘 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 빌드 실패 또는 데이터 소실 위험 1건 이상 |

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 동작하는가

- [ ] `isLoading = true` 상태일 때 `InvestmentOnboardingView`에 로딩 인디케이터가 표시된다 — FAIL 조건: 로딩 중에 기존 "투자 성향을 불러오는 중이에요" 정적 텍스트만 보이고 스피너가 없는 경우
- [ ] `errorMessage != nil` 상태일 때 오류 안내 메시지(예: "아직 투자 성향을 불러오지 못했어요")가 표시된다 — FAIL 조건: 오류 발생 시 로딩 중 텍스트와 동일한 UI가 표시되는 경우
- [ ] `InvestmentOnboardingView`가 외부로부터 `isLoading`과 `errorMessage` 정보를 전달받는다 — FAIL 조건: 뷰가 해당 파라미터 없이 `investmentProfile`만 받는 경우
- [ ] 기존 성공 케이스(`investmentProfile != nil`)의 히어로·ETF·강점·리스크 섹션 순차 애니메이션이 그대로 동작한다 — FAIL 조건: 프로필이 있을 때 섹션이 한꺼번에 나타나거나 일부 섹션이 누락되는 경우

### [필수] Functionality — 핵심 플로우가 막힘 없이 동작하는가

- [ ] 로딩 중(`isLoading = true`)에도 "투자 시작하기" 버튼이 노출된다 — FAIL 조건: 버튼이 숨겨져 있어 메인 화면으로 진입이 불가능한 경우
- [ ] 오류 발생(`errorMessage != nil`) 시에도 "투자 시작하기" 버튼이 노출된다 — FAIL 조건: 버튼이 없어 사용자가 온보딩을 완료하지 못하는 경우
- [ ] "투자 시작하기" 버튼 탭 시 `finishOnboarding()` 호출 후 `MainTabView`로 이동한다 — FAIL 조건: 버튼을 탭해도 화면 전환이 없는 경우
- [ ] `investmentProfile = nil` + `isLoading = false` + `errorMessage = nil`(분석 미실행) 상태에서 크래시 없이 뷰가 렌더링된다 — FAIL 조건: 앱이 크래시하는 경우

### [권장] Visual Design — 인터페이스가 일관된 느낌인가

- [ ] 로딩 인디케이터는 화면 중앙에 배치되어 사용자의 시선을 유도한다 — FAIL 조건: 인디케이터가 화면 끝이나 가려진 위치에 있는 경우
- [ ] 오류 안내 메시지는 "메인 화면에서 확인할 수 있어요"와 함께 표시되어 다음 행동을 안내한다 — FAIL 조건: 오류 메시지만 있고 다음 행동 안내가 없는 경우
- [ ] 로딩·오류 상태의 UI가 기존 빈 상태 디자인(📊 이모지, 여백 등)과 시각적으로 일관성이 있다 — FAIL 조건: 로딩/오류 UI가 다른 화면과 동떨어진 스타일인 경우

### [권장] Code Quality — 연결이 끊어진 곳은 없는가

- [ ] `OnboardingFlowView`가 `investmentVM.isLoading`과 `investmentVM.errorMessage`를 `InvestmentOnboardingView`에 올바르게 전달한다 — FAIL 조건: 항상 기본값(`false`, `nil`)이 전달되는 경우
- [ ] 기존 `InvestmentOnboardingView` 호출부(`#Preview`, `UITestInvestmentAnalyzer` 등)가 새 파라미터에 맞게 업데이트되어 빌드가 성공한다 — FAIL 조건: 빌드 오류 발생
- [ ] 기존 XCUITest 13건이 모두 통과한다 — FAIL 조건: 기존 테스트 중 1건 이상 실패

### [선택] 추가 검증

- [ ] 로딩 완료 후(`investmentProfile`이 nil → non-nil로 변경) 뷰가 자동으로 프로필 콘텐츠로 전환된다

## Generator 자체 점검 결과

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | 성공 | Debug-iphonesimulator, generic/platform=iOS Simulator |
| 단위 테스트 | 18건 중 18건 통과 | 기존 14건 + 신규 4건 (loading/error/fallback/success 상태 분기) |
| Product Depth 자체 점검 | PASS | `isLoading`, `errorMessage` 파라미터 추가 완료. loadingView에 ProgressView, errorView에 "불러오지 못했어요" 텍스트 구현. 성공 시 기존 순차 애니메이션 .task 그대로 유지 |
| Functionality 자체 점검 | PASS | 세 분기(loadingView/errorView/fallbackView) 모두 `onAppear { showButton = true }` 적용 → 모든 상태에서 "투자 시작하기" 버튼 노출. 버튼 탭 → `onFinish()` → `finishOnboarding()` 콜백 체인 기존과 동일 |
