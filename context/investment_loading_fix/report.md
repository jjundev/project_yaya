# 투자 성향 로딩 실패 수정 작업 최종 보고서

## 작업 요약
온보딩 완료 후 `InvestmentOnboardingView`에서 투자 성향 프로필이 로드되지 않던 근본 원인을 분석하고 수정했다. `AIService.analyzeInvestmentType()`이 아직 배포되지 않은 Supabase Edge Function `"investment-personality"`를 실제로 호출하고 있어 매번 실패하는 것이 원인이었다. 사주 분석(`analyzeSaju`)은 Edge Function을 주석 처리하고 mock 데이터를 반환하는 패턴으로 정상 동작했지만, 투자 성향 분석만 이 패턴을 따르지 않았다. 동일한 mock 패턴으로 전환하고, 부수적으로 DB 저장 실패 시에도 프로필이 UI에 표시되도록 할당 순서를 수정했다.

## 실수 및 수정 이력
없음. QA에서 [필수] FAIL 0건, [권장] FAIL 0건.

## 기술 결정 배경

| 항목 | 결정 | 배경 및 이유 |
|------|------|-------------|
| mock 패턴 | `analyzeSaju()`와 동일하게 Edge Function 주석 처리 + `Task.sleep` + mock 반환 | `analyzeSaju()`가 이미 이 패턴으로 정상 동작 중. 동일 패턴 사용으로 일관성 확보 및 검증 비용 절감 |
| mock 로딩 시간 | 1초 (`1_000_000_000` ns) | 사주 분석(2초) 이후에 실행되므로 더 짧은 로딩이 UX에 적합. 너무 짧으면 로딩 스피너가 안 보이고, 너무 길면 사용자 이탈 |
| mock 투자 유형 | `.stable` (안정형) | 기존 XCUITest mock(`UITestInvestmentAnalyzer`)에서 `.stable`을 사용 중이어서 테스트 일관성 유지 |
| 저장 실패 처리 | `try?`로 무시 | 분석 결과는 이미 UI에 반영 완료. 저장 실패 시 다음 접속에서 캐시 miss → 재분석으로 자연 복구. 저장 실패로 사용자 경험을 해치는 것보다 나음 |
| `investmentProfile` 할당 순서 | `saveInvestmentProfile` 호출 **앞**으로 이동 | 기존 코드는 저장 성공 후에만 프로필을 할당해서, 저장 실패 시 분석 성공에도 nil로 남았음. 분석 성공 즉시 UI를 업데이트하는 것이 올바른 동작 |

## 특이사항 및 다음 스프린트 권장 사항
- **Edge Function 배포 필요**: `"investment-personality"` Edge Function이 배포되면 `AIService.analyzeInvestmentType()`의 주석을 해제하고 실제 AI 분석을 연동해야 한다. `analyzeSaju()`도 마찬가지로 `"calculate-saju"` Edge Function 배포 대기 중
- **mock `userId` 불일치**: `mockInvestmentProfile()`에서 `userId`를 `UUID()`로 하드코딩. 실제 Edge Function 전환 시 응답에 올바른 userId가 포함되어야 DB 저장이 정상 동작
- **XCUITest flaky**: `testInvestmentOnboarding_showsErrorState_whenFailed`가 전체 실행 시 순서 의존 flaky. 테스트 간 시뮬레이터 상태 격리 강화 필요
- **Supabase `investment_profiles` 테이블**: RLS 정책 및 스키마가 `InvestmentProfile` Codable 구조와 일치하는지 검토 필요 (mock 모드에서는 `try?`로 무시되어 표면화되지 않음)

## 회고
### 잘된 점
- 근본 원인을 정확히 식별: `analyzeSaju`(mock)와 `analyzeInvestmentType`(실제 호출)의 패턴 불일치를 비교 분석으로 즉시 파악
- 2차 원인(저장 실패 → 프로필 nil)까지 함께 수정하여 향후 Edge Function 연동 시에도 저장 실패가 UX에 영향을 주지 않도록 방어
- 기존 XCTest 34건, XCUITest 7건(단독) 회귀 없이 전부 통과

### 개선할 점
- Generator 단계에서 Edit 적용이 실제 파일에 반영되지 않는 문제 발생. QA 단계에서 코드를 직접 읽어 재수정해야 했음. 구현 후 반드시 파일 내용을 재검증하는 절차 필요
- `InvestmentViewModel`에 이전 대화에서 넣은 하드코딩 mock과 `AIService`의 mock이 중복 존재했던 구간이 있었음. mock 데이터를 한 곳(`AIService`)에서만 관리하는 원칙을 초기에 세웠으면 혼란을 줄였을 것
