# 투자 성향 mock 우선 로딩 QA 결과

## 최종 판정: PASS
판정 근거: [필수] 항목 5건 전부 PASS, [권장] 항목 4건 전부 PASS

## 빌드 및 단위 테스트
- 빌드: 성공
- XCTest(단위 테스트): Generator 자체 점검 참조 (44건 중 44건 통과)
- XCUITest(UI 테스트): 해당 없음 — 이유: `UITestInvestmentAnalyzer`가 `InvestmentViewModel.loadInvestmentProfile()`을 우회하므로, 이번 수정(캐시 `try?`) 경로를 XCUITest로 검증 불가. 기존 XCUITest 5건(`testFullFlow_reachesInvestmentOnboardingView` 등)은 회귀 방지 목적으로 유효하며 변경 없음.

## 체크리스트 결과

### [필수] Product Depth
- [PASS] 온보딩 완료 후 `InvestmentOnboardingView`에 투자 성향 프로필 콘텐츠가 표시된다 — `InvestmentViewModel.swift:23` `try?` 처리로 Supabase 실패 시 `analyzeInvestmentType()`(mock)으로 폴스루, `investmentProfile` 설정 후 profileContent 분기 진입 확인
- [PASS] Supabase 미연결/미준비 상태에서도 mock 프로필이 정상 표시된다 — 캐시 실패가 `nil`로 처리되어 catch 블록에 도달하지 않음
- [PASS] 투자 성향 로딩 중 일시적으로 로딩 스피너가 표시된 후 프로필로 전환된다 — `isLoading = true` (line 16) → AIService 1초 sleep → `isLoading = false` & `investmentProfile` 설정 순서 확인

### [필수] Functionality
- [PASS] 사주 분석 완료 → "시작하기" 탭 → `InvestmentOnboardingView` 진입 → 프로필 표시 → "투자 시작하기" 탭 → 메인 화면 플로우가 끊김 없이 완료된다 — 코드 변경이 `InvestmentViewModel.swift:23` 1줄에 한정, 플로우 제어 코드 수정 없음
- [PASS] "투자 시작하기" 버튼 탭 시 `finishOnboarding()` 호출 — 이번 수정 범위 밖, 변경 없음

### [권장] Visual Design
- [PASS] `errorView` 코드가 삭제되지 않고 존재한다 — `InvestmentOnboardingView.swift:298` 확인
- [PASS] `fallbackView` 코드가 삭제되지 않고 존재한다 — `InvestmentOnboardingView.swift:321` 확인

### [권장] Code Quality
- [PASS] 캐시 실패 시 AI 분석으로 폴스루한다 — `try? await supabase.getInvestmentProfile()` 실패 시 nil 반환, if 조건 미충족, `analyzeInvestmentType()` 실행으로 이어짐
- [PASS] AI 분석 실패 시 에러 화면이 표시된다 — `analyzeInvestmentType()` throw 시 catch 블록(line 36)에서 `errorMessage` 설정, `errorView` 분기 진입

## FAIL 항목 상세
없음

## 다음 액션
### PASS인 경우
다음 기능 개발로 이동 가능.

[참고] XCUITest 아키텍처 한계:
- `UITestInvestmentAnalyzer`가 `InvestmentViewModel.loadInvestmentProfile()`을 완전히 우회하는 구조이므로, 실제 VM의 캐시 실패 → mock 폴스루 경로는 XCUITest로 검증 불가
- 다음 스프린트에서 `"live_mock"` 모드(실제 VM 호출 + Supabase만 mock) 추가를 권장
