# 투자 정체성 온보딩 화면 작업 최종 보고서

## 작업 요약

사주 분석 완료 후 `FirstFortuneResultView`와 `MainTabView` 사이에 신규 화면 `InvestmentOnboardingView`를 삽입했다. 이 화면은 사주 결과를 "투자의 언어"로 번역해 사용자가 자신의 투자 성향 타입(공격형🔥 / 안정형🛡️ / 가치투자형💎 / 성장추구형🚀)을 처음으로 각인하는 "공개(reveal)" 경험을 제공한다. 히어로 섹션(이모지 + 타입명 + 설명), 사주 근거(`sajuBasis`), ETF 목록(최대 5개), 투자 강점(최대 3개), 리스크(최대 2개), 하단 고정 CTA("투자 시작하기")를 섹션별 순차 페이드인 애니메이션과 함께 구현했다. `InvestmentOnboardingTests.swift` 14개 XCTest, `OnboardingFlowUITests.swift` 6개 XCUITest를 작성하여 검증했다.

---

## 실수 및 수정 이력

| 항목 | 문제 내용 | 원인 | 수정 방법 |
|------|-----------|------|-----------|
| `sajuBasis` 빈 문자열 처리 | `basisSection`이 조건 없이 항상 렌더링되어 `sajuBasis`가 빈 문자열일 때도 섹션이 노출됨 | 렌더링 조건 누락 | `if !profile.sajuBasis.isEmpty { basisSection(...) }` 가드 추가 |
| XCUITest 버튼 중복 매칭 | `TabView` 내 Step 1·2 모두 "다음" 텍스트를 공유해 `app.buttons["다음"]`이 두 개 매칭 | 동일 레이블의 버튼이 동시에 존재 | `onboarding.next.gender` / `onboarding.next.birth` accessibilityIdentifier 도입 |
| Mock 분석 비동기 미완료 | `Task.sleep(500ms)` 후 `showResult = true`를 설정하는 `startMockAnalysis()`가 XCUITest 환경에서 미실행 | UITest 컨텍스트에서 async Task가 신뢰할 수 없음 | main 브랜치의 `UITestSajuAnalyzer` / `UITestInvestmentAnalyzer` 패턴으로 교체 |
| 병합 충돌 — 5개 파일 | main에 `OnboardingAnalysisCoordinator` 아키텍처가 선행 병합되어 `OnboardingFlowView.swift`, `YayaApp.swift`, `project.yml`, `OnboardingFlowUITests.swift`, `project.pbxproj` 충돌 | 브랜치 작업 중 main에 구조적 변경 병합 | main의 Coordinator 아키텍처를 기반으로 채택하고, `showInvestmentOnboarding` 상태·플로우를 그 위에 통합 |
| XCUITest `testRetry` 불안정 | `testRetryFromResultGoesBackToGenderSelection`이 전체 suite 5번째 실행 시 간헐적 실패 | 앞선 4개 테스트 누적으로 시뮬레이터 `scheduleResultTransition` Task.sleep 타이밍 불안정 | timeout 12s → 20s 연장. 근본 해결 미완 → 알려진 flaky 항목으로 PR에 문서화 |
| GoogleSignIn / KakaoSDK 누락 | `xcodegen` 재생성 후 패키지 의존성이 `.xcodeproj`에서만 관리되던 구성이 소실 | `project.yml`에 패키지 항목이 없었음 | `project.yml`에 `GoogleSignIn(9.1.0)`, `KakaoOpenSDK(2.27.2)` 명시적 추가 |
| `YayaTests` Info.plist 미생성 | 테스트 타겟 빌드 시 "Missing Info.plist" 오류 | `project.yml`에 `GENERATE_INFOPLIST_FILE: YES` 누락 | `YayaTests` 설정에 `GENERATE_INFOPLIST_FILE: YES` 추가 |

---

## 기술 결정 배경

| 항목 | 결정 | 배경 및 이유 |
|------|------|-------------|
| 타입별 색상 위치 | `InvestmentOnboardingView` 내부 `switch` | 색상은 UI 관심사이므로 도메인 모델(`InvestmentType`) 수정 불필요. View 단 분기로 충분 |
| 애니메이션 구현 | `FadeSlideInInvestment` modifier 재선언 | `FirstFortuneResultView`의 `FadeSlideIn`이 `private`으로 선언되어 외부 접근 불가. 복사 후 이름 변경으로 동일 패턴 유지 |
| 상태 변수 방식 | `showInvestmentOnboarding @State` 추가 | 기존 `showResult` 패턴과 대칭을 이루며 Coordinator 아키텍처와 충돌 없이 통합 가능 |
| ETF 데이터 소스 | `profile.recommendedETFs` 우선, 비어 있으면 `type.recommendedETFs` | AI 실분석 결과를 우선하되, 분석 실패·nil 대응 fallback 보장 |
| UI 테스트 Mock 방식 | main의 `UITestSajuAnalyzer` / `UITestInvestmentAnalyzer` 채택 | 자체 `startMockAnalysis()`는 XCUITest 환경에서 async Task 완료가 보장되지 않음. main의 protocol 기반 교체형 Mock이 더 안정적 |
| Coordinator 병합 방향 | main 아키텍처 기반 위에 `showInvestmentOnboarding` 통합 | 현재 브랜치의 구현보다 main의 `OnboardingAnalysisCoordinator`가 더 완성도 높음. 역방향 병합 대신 순방향 편승 |

---

## 특이사항 및 다음 스프린트 권장 사항

- **`testRetryFromResultGoesBackToGenderSelection` flaky**: 전체 suite에서 5번째 실행 시 timeout 초과 실패. 개별 실행 시 통과. `scheduleResultTransition`의 `Task.sleep(1.5s)`이 시뮬레이터 누적 상태에서 지연되는 것으로 추정. 다음 스프린트에서 `scheduleResultTransition` 로직을 `clock` 주입 방식으로 교체하거나 `Task` determinism 보장 여부를 검토 권장
- **`FadeSlideIn` 중복 선언**: 현재 `FirstFortuneResultView`와 `InvestmentOnboardingView`에 동일 modifier가 각각 `private`으로 선언됨. 공통 `ViewModifiers.swift`로 추출 고려
- **`sajuBasis` 빈 문자열**: 실제 AI 응답에서 `sajuBasis` 필드가 항상 채워지는지 보장이 없음. 백엔드 계약(API 응답 명세)에 non-empty 조건 추가 권장
- **투자 타입 색상 접근성**: 타입별 gradient 색상이 다크 모드에서 충분한 명도 대비를 갖는지 공식 accessibility audit 미시행. 다음 스프린트에서 `accessibility_audit.py` 실행 권장
- **다음 스프린트 scope (spec.md 미포함 항목)**: 복리 계산기, ETF 상세/외부 링크, 구독 플랜 업셀링, 소셜 공유, 타입 비교 화면

---

## 회고

### 잘된 점
- 실제 XCUITest 시뮬레이터 실행으로 mock 구조 문제를 조기 발견함 (코드 리뷰만으로는 발견 불가했던 비동기 issue)
- main 병합 충돌 시 단순 코드 merge가 아닌 아키텍처 의도를 파악하여 올바른 방향으로 통합함
- spec.md의 모든 [필수] DoD 항목을 XCTest + XCUITest 양쪽으로 커버함
- 5개 파일 충돌 해결 후 테스트 재실행으로 회귀 없음을 확인하는 절차를 준수함

### 개선할 점
- `FadeSlideIn` modifier를 처음부터 공유 가능한 위치에 선언했다면 `FadeSlideInInvestment` 중복이 없었을 것
- XCUITest mock 아키텍처를 설계할 때 main 브랜치의 기존 패턴(`UITestSajuAnalyzer`)을 먼저 확인했다면 `startMockAnalysis()` 작성 후 교체하는 비용을 줄일 수 있었음
- flaky test의 근본 원인(`Task.sleep` determinism)은 시간 제약으로 해결하지 못하고 timeout 증가로 우회함. `clock` 주입 패턴을 처음부터 적용했으면 회피 가능했던 문제
