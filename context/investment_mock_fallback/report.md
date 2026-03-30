# 투자 성향 mock 우선 로딩 작업 최종 보고서

## 작업 요약

사주 분석 완료 후 `InvestmentOnboardingView`에서 "아직 투자 성향을 불러오지 못했어요" 에러 화면이 표시되는 문제를 수정했다. 이전 스프린트(`investment_loading_fix`)에서 `AIService.analyzeInvestmentType()`을 mock 패턴으로 전환했음에도 불구하고, 그 이전 단계인 Supabase 캐시 확인(`getInvestmentProfile`)이 throw하여 catch 블록으로 직행하는 문제가 남아 있었다. `InvestmentViewModel.swift` line 23의 `try await`를 `try?`로 변경하여 Supabase 실패를 캐시 miss로 처리하고 mock 분석으로 폴스루하도록 수정했다. 변경은 1줄에 한정되며 기존 에러/로딩/fallback UI는 그대로 유지된다.

## 실수 및 수정 이력

없음. QA에서 [필수] FAIL 0건, [권장] FAIL 0건.

## 기술 결정 배경

| 항목 | 결정 | 배경 및 이유 |
|------|------|-------------|
| 캐시 실패 처리 | `try?`로 에러 무시 | Supabase가 현재 전혀 준비되지 않은 상태. 캐시 실패는 "아직 저장된 프로필이 없음"과 동일하게 취급해야 하므로 nil 반환으로 폴스루. catch 블록 전파는 잘못된 동작 |
| 에러/fallback UI 유지 | 삭제 없이 그대로 보존 | Supabase 연동 이후 저장된 프로필을 불러오는 흐름과, AI 분석 자체가 실패하는 경우 모두 향후 필요. 제거하면 다음 스프린트에서 재작성 필요 |

## 특이사항 및 다음 스프린트 권장 사항

- **XCUITest 아키텍처 한계**: `UITestInvestmentAnalyzer`가 `InvestmentViewModel.loadInvestmentProfile()`을 완전히 우회하는 구조로, 이번 수정 경로(캐시 `try?` → mock 폴스루)를 XCUITest로 검증하는 것이 구조적으로 불가하다. `"live_mock"` 모드(실제 VM 호출 + Supabase만 mock 처리) 추가를 권장한다.
- **Supabase 준비 필요**: `investment_profiles` 테이블 설정, RLS 정책, `getInvestmentProfile` / `saveInvestmentProfile` 정상 동작 검증이 다음 스프린트 선행 조건이다.
- **Edge Function 배포 필요**: `"investment-personality"` Edge Function이 배포되면 `AIService.analyzeInvestmentType()`의 주석을 해제하고 실제 AI 분석을 연동해야 한다.

## 회고

### 잘된 점
- 근본 원인을 정확히 식별: `investment_loading_fix` 스프린트에서 mock 전환을 완료했음에도 그 앞 단계인 Supabase 캐시 확인이 throw하는 구조를 빠르게 파악
- 변경 범위를 최소화: 1줄 수정으로 문제를 해결하고 기존 UI와 테스트에 영향을 주지 않음
- QA 단계에서 XCUITest mock 아키텍처의 구조적 한계를 발견하고 문서화하여 다음 스프린트 대응 방향을 명시

### 개선할 점
- XCUITest mock이 실제 ViewModel을 우회하는 구조로 인해, ViewModel 로직 변경이 XCUITest로 검증되지 않는 사각지대가 존재한다. `"live_mock"` 모드를 조기에 설계했다면 이번 수정도 XCUITest로 E2E 검증할 수 있었다.
