# 투자 성향 mock 우선 로딩 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 stub 또는 미구현 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 크래시 또는 플로우 막힘 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 빌드 실패 또는 데이터 소실 위험 1건 이상 |

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 동작하는가

- [ ] 온보딩 완료 후 `InvestmentOnboardingView`에 투자 성향 프로필 콘텐츠(타입명, ETF 목록, 강점, 리스크)가 표시된다 — FAIL 조건: 프로필 콘텐츠 대신 에러 화면("아직 투자 성향을 불러오지 못했어요") 또는 fallback 화면이 표시되는 경우
- [ ] Supabase 미연결/미준비 상태에서도 mock 프로필이 정상 표시된다 — FAIL 조건: Supabase 실패 시 에러 화면으로 귀결되는 경우
- [ ] 투자 성향 로딩 중 일시적으로 로딩 스피너("투자 성향을 분석하는 중이에요")가 표시된 후 프로필로 전환된다 — FAIL 조건: 스피너 없이 즉시 프로필 또는 에러 화면이 표시되는 경우

### [필수] Functionality — 핵심 플로우가 막힘 없이 동작하는가

- [ ] 사주 분석 완료 → "시작하기" 탭 → `InvestmentOnboardingView` 진입 → 프로필 표시 → "투자 시작하기" 탭 → 메인 화면 진입이 끊김 없이 완료된다 — FAIL 조건: 어느 단계에서든 크래시 또는 화면 전환이 막히는 경우
- [ ] `InvestmentOnboardingView`의 "투자 시작하기" 버튼 탭 시 `finishOnboarding()`이 호출되어 메인 화면으로 이동한다 — FAIL 조건: 버튼 탭 후 화면이 바뀌지 않거나 크래시가 발생하는 경우

### [권장] Visual Design — 인터페이스가 일관된 느낌인가

- [ ] 기존 에러 화면("아직 투자 성향을 불러오지 못했어요") UI 코드가 삭제되지 않고 그대로 존재한다 — FAIL 조건: `errorView`가 코드에서 제거된 경우
- [ ] 기존 fallback 화면("투자 성향을 불러오는 중이에요") UI 코드가 삭제되지 않고 그대로 존재한다 — FAIL 조건: `fallbackView`가 코드에서 제거된 경우

### [권장] Code Quality — 연결이 끊어진 곳은 없는가

- [ ] `InvestmentViewModel.loadInvestmentProfile()`에서 Supabase 캐시 확인 실패 시 AI 분석(mock)으로 폴스루한다 — FAIL 조건: 캐시 확인 실패가 catch 블록으로 전파되어 `errorMessage`가 설정되는 경우
- [ ] AI 분석(`analyzeInvestmentType`) 자체가 실패한 경우에는 여전히 에러 화면이 표시된다 — FAIL 조건: AI 분석 실패 시 에러 화면이 아닌 빈 화면이나 크래시가 발생하는 경우

### [선택] 추가 검증

- [ ] `InvestmentViewModelTests`에서 Supabase 캐시 실패 시 mock 프로필이 반환되는 경우를 단위 테스트로 검증한다

## Generator 자체 점검 결과
> Generator가 구현 완료 후 채웁니다.

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | 성공 | |
| XCTest(단위 테스트) | 44건 중 44건 통과 | InvestmentOnboardingTests 19건 포함 |
| XCUITest(UI 테스트) | - (QA 담당) | |
| Product Depth 자체 점검 | PASS | `try?`로 Supabase 실패 시 mock 분석 진행 확인 |
| Functionality 자체 점검 | PASS | 캐시 실패 → AI 분석 → 프로필 표시 플로우 코드 경로 확인 |
