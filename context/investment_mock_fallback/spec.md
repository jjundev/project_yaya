# 투자 성향 mock 우선 로딩 스펙

## 개요

사주 분석 완료 후 투자 성향 프로필을 로드할 때, Supabase 캐시 확인이 실패하면 mock 분석에 도달하기 전에 전체 플로우가 에러로 귀결된다. 현재 Supabase가 전혀 준비되지 않은 상태이므로, 투자 성향 로딩 시 Supabase 의존 없이 mock 데이터를 우선적으로 사용하도록 변경한다. 에러 화면 등 기존 fallback UI는 그대로 유지하되, Supabase 미준비 상태에서도 사용자가 투자 성향 프로필을 정상적으로 확인할 수 있도록 한다.

## 범위

### 포함
- 투자 성향 로딩 시 Supabase 캐시 확인 실패가 전체 플로우를 중단하지 않도록 변경
- Supabase 미준비 상태에서 mock 데이터로 투자 성향 프로필이 정상 표시되도록 보장
- 기존 에러/로딩/fallback UI는 그대로 유지

### 미포함 (다음 스프린트)
- Supabase `investment_profiles` 테이블 설정 및 RLS 정책
- Edge Function `"investment-personality"` 배포 및 실제 AI 분석 연동
- 투자 성향 저장 로직 정상화

## 사용자 스토리

### 온보딩 투자 성향 확인
- 사용자는 사주 분석 완료 후 "시작하기"를 탭하면 투자 성향 프로필(타입, ETF, 강점, 리스크)을 확인할 수 있다
- 사용자는 Supabase 연결 상태와 무관하게 투자 성향 프로필을 볼 수 있다
- 사용자는 투자 성향 로딩 중 잠시 스피너를 본 후 프로필로 전환되는 것을 경험한다

### 기존 동작 유지
- 사용자는 향후 Supabase가 준비되면 캐시된 프로필을 우선적으로 받을 수 있다
- 사용자는 AI 분석 자체가 실패한 경우에는 기존 에러 화면을 그대로 볼 수 있다

## 완료 조건 (Definition of Done)

- [ ] 온보딩 완료 시 `InvestmentOnboardingView`에 투자 성향 프로필 콘텐츠가 표시된다
- [ ] Supabase 미연결/미준비 상태에서도 mock 프로필이 정상 표시된다
- [ ] 기존 에러/로딩/fallback UI 코드가 변경 없이 유지된다
- [ ] 기존 XCTest가 모두 통과한다

## 참고 사항

- 이전 `investment_loading_fix` 스프린트에서 `AIService.analyzeInvestmentType()`은 이미 mock 패턴으로 전환됨
- 현재 문제는 mock 분석 호출 이전의 Supabase 캐시 확인(`getInvestmentProfile`)이 throw하여 catch 블록으로 직행하는 것
- 에러/fallback UI는 향후 Supabase 연동 시 필요하므로 제거하지 않음
