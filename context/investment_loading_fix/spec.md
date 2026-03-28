# 투자 성향 로딩 실패 수정 스펙

## 개요

온보딩 완료 후 `InvestmentOnboardingView`로 진입할 때 투자 성향 프로필이 로드되지 않는다. 근본 원인은 `AIService.analyzeInvestmentType()`이 아직 배포되지 않은 Supabase Edge Function `"investment-personality"`를 실제로 호출하기 때문이다. 사주 분석(`analyzeSaju`)은 Edge Function을 주석 처리하고 mock 데이터를 반환하는 구조로 정상 동작하지만, 투자 성향 분석은 이 패턴을 따르지 않아 매번 실패한다. 이 스펙은 투자 성향 분석을 사주 분석과 동일한 mock 패턴으로 전환하여 프로필이 정상 표시되도록 한다.

## 범위

### 포함
- `AIService.analyzeInvestmentType()`을 mock 데이터 반환 방식으로 전환 (Edge Function 호출 주석 처리)
- 분석 성공 후 저장 실패 시에도 프로필이 표시되도록 상태 할당 순서 수정
- mock 투자 성향 프로필 데이터 정의

### 미포함 (다음 스프린트)
- `"investment-personality"` Edge Function 실제 배포 및 연동
- 투자 성향 유형별 사주 기반 맞춤 분석 로직
- Supabase `investment_profiles` 테이블 RLS 정책 검토

## 사용자 스토리

### 온보딩 완료 후 투자 성향 확인
- 사용자는 온보딩 사주 분석 완료 후 "투자 시작하기"를 탭하면 투자 성향 프로필 콘텐츠(투자 유형, ETF 추천, 강점)를 볼 수 있다
- 사용자는 "투자 성향을 불러오는 중이에요" 상태에서 무한 대기하지 않는다
- 사용자는 투자 성향 로딩 중 일시적인 스피너를 본 후 프로필 콘텐츠로 전환되는 것을 경험한다

## 완료 조건 (Definition of Done)

- [ ] `success` 모드 온보딩 완료 시 `InvestmentOnboardingView`에 투자 성향 프로필 콘텐츠가 표시된다
- [ ] 투자 성향 로딩 중 일시적으로 스피너가 노출된다 (이전 작업 유지)
- [ ] 네트워크 미연결 상태에서도 mock 데이터로 프로필이 표시된다
- [ ] 기존 XCTest 18건, XCUITest(단독 실행 기준) 5건이 모두 통과한다
- [ ] `AIService.analyzeInvestmentType()` 내 Edge Function 호출 코드가 주석 처리되고 TODO 주석이 유지된다

## 참고 사항

- `analyzeSaju()`의 mock 패턴을 그대로 따른다 (`ios/Yaya/Yaya/Services/AIService.swift:9-24`)
- mock 투자 성향 유형은 `.stable`을 사용한다 (기존 XCUITest mock과 일치)
- `saveInvestmentProfile` 실패는 다음 접속 시 재분석으로 대체 가능하므로 조용히 무시한다
- 이전 작업에서 추가된 `isLoading`/`errorMessage` UI 상태 표시(`InvestmentOnboardingView`)는 이번 수정 후에도 동작해야 한다
