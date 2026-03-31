# 오늘의 운세 상세 화면 플랜 검토 결과

## 최종 판정: 구현 진행 가능
판정 근거: [차단] 이슈 없음. [경고] 2건, [제안] 2건 발견 — 구현 시 주의 필요.

## 검토 요약

| 등급 | 건수 |
|------|------|
| [차단] | 0 |
| [경고] | 2 |
| [제안] | 2 |

## 스펙 정합성 검토

### 요구사항 커버리지
- [PASS] FortuneHomeView 카드 탭 → 상세 화면 진입 — plan.md 위치: 구현 순서 4단계
- [PASS] 헤더(날짜 + 요약) — plan.md 위치: 구현 순서 3단계
- [PASS] 영역별 상세 해설 4개 (사랑/재물/건강/직장) — plan.md 위치: 구현 순서 1단계 + 3단계
- [PASS] AI 개인화 메시지 — plan.md 위치: 구현 순서 1단계(personalMessage) + 3단계
- [PASS] 행운의 숫자·색 — plan.md 위치: 구현 순서 3단계
- [PASS] 공유 기능(ShareLink) — plan.md 위치: 구현 순서 3단계
- [경고] 행운의 방향·시간대 — spec.md "포함" 목록에 "행운의 방향, 행운의 시간대"가 명시되어 있으나, spec.md "미포함" 목록에도 "행운의 방향·시간대 데이터 모델 추가"가 있어 **스펙 자체에 모순이 존재**한다. plan.md는 미포함으로 처리했고 checklist.md도 숫자·색만 검증한다. 방향은 일관되지만 spec 모순은 명시적으로 특이사항에 기록되어야 한다. — plan.md 위치: 구현 범위 > 포함하지 않는 항목

### 범위 일탈
- [PASS] plan.md에 spec.md에 없는 항목 없음

### 역할 월경
- [PASS] plan.md의 기술 결정 및 구현 순서는 Generator 영역 내

### 테스트 포함 여부
- [PASS] XCTest 계획: FortuneDetailTests.swift (신규 필드 디코딩, mock 데이터 검증)
- [PASS] XCUITest 계획: FortuneDetailUITests.swift (진입, 섹션 표시, 뒤로가기)
- [PASS] checklist [필수] 항목 대부분에 대응하는 테스트 계획 존재

## 실행 안전성 검토

### 기존 코드 재사용
- [경고] plan.md 기술 결정에서 "기존 scoreItem 패턴(도트 5개) 재사용"이라고 명시했으나, `scoreItem(icon:label:score:color:)`는 `FortuneHomeView`의 **private** 함수이다. FortuneDetailView에서 직접 호출할 수 없으므로, (1) 공유 헬퍼로 추출하거나 (2) FortuneDetailView 내에 유사 함수를 별도 구현해야 한다. — 확인한 파일: `ios/Yaya/Yaya/Views/Fortune/FortuneHomeView.swift:174`

### 기존 코드 파괴 위험
- [PASS] FortuneContent 필드 추가: 모두 `String?` optional — 기존 JSON 디코딩 하위 호환 보장 — 영향 범위: Fortune.swift, 기존 테스트 `testFortuneContent_decodesWithoutOptionalFields`는 통과 예상
- [PASS] FortuneHomeView NavigationLink 감싸기: `.buttonStyle(.plain)` 적용 시 기존 스타일 유지 — 영향 범위: FortuneHomeView.swift:120-172
- [PASS] 의존성·스키마 변경 없음

### 단계 순서의 논리성
- [PASS] 모델(1단계) → Mock(2단계) → View(3단계) → 네비게이션(4단계) → 빌드(5단계) → 테스트(6~7단계) — 의존 관계 올바름

### 구체성
- [PASS] 각 단계별 대상 파일, 변경 내용, View 구조가 명확함

### 실현 가능성
- [PASS] ShareLink: SwiftUI 빌트인, iOS 16+ — 앱 타겟 iOS 17. 프로젝트 내 첫 사용이지만 추가 의존성 불필요 — 확인한 파일: `ios/Yaya/project.yml:6` (deploymentTarget: iOS 17.0)
- [PASS] NavigationLink: 이미 사용 중 — 확인한 파일: `ios/Yaya/Yaya/Views/Common/ProfileView.swift:94`
- [PASS] Makefile 타겟(build, test-unit, test-quick): 존재 — 확인한 파일: `ios/Yaya/Makefile`
- [PASS] UITEST_MAIN_TAB 환경변수: 앱에서 MainTabView 직접 진입 지원 — 확인한 파일: `ios/Yaya/Yaya/YayaApp.swift:11`

### 하드코딩
- [PASS] Mock 데이터의 한국어 문자열은 기존 패턴과 동일 (AIService.swift)

### 내부 일관성
- [PASS] 기술 결정과 구현 순서 간 모순 없음

## 이슈 목록

### [경고] spec.md 행운 아이템 범위 모순 미기록
- 위치: plan.md > 구현 범위 > 포함하지 않는 항목
- 내용: spec.md "포함"에 행운의 방향·시간대가 있으나 "미포함"에도 데이터 모델 추가 불가로 명시되어 모순이다. plan.md는 미포함 처리했으나, **특이사항 섹션에 spec 모순을 명시적으로 기록하지 않았다**.
- 수정 방향: plan.md 특이사항에 "spec.md의 행운 아이템 범위 모순(포함에 방향·시간대 명시 ↔ 미포함에 데이터 모델 불가)으로 인해 숫자·색만 구현. 방향·시간대는 FortuneContent에 필드가 없으므로 다음 스프린트에서 모델 추가 후 구현" 추가 권장.

### [경고] scoreItem private 함수 재사용 불가
- 위치: plan.md > 기술 결정 > "점수 시각화" 행
- 내용: `FortuneHomeView.scoreItem(icon:label:score:color:)`는 private이므로 FortuneDetailView에서 직접 호출 불가. 재사용한다는 결정과 실제 접근성이 불일치.
- 수정 방향: (1) FortuneDetailView 내에 동일 패턴의 로컬 함수를 구현하거나, (2) 공통 View 컴포넌트로 추출. 사용자 판단.

### [제안] XCUITest에서 UITEST_MAIN_TAB 사용 명시
- 위치: plan.md > 구현 순서 7단계
- 내용: FortuneDetailUITests는 MainTabView에서 시작해야 하므로 `launchEnvironment["UITEST_MAIN_TAB"] = "1"` 설정이 필요하다. plan.md 7단계에 이 진입 방식을 명시하면 Generator가 더 정확히 구현할 수 있다.

### [제안] FortuneHomeView accessibilityIdentifier 추가 필요
- 위치: plan.md > 구현 순서 4단계
- 내용: 현재 FortuneHomeView의 dailyFortuneCard에는 accessibilityIdentifier가 없다. XCUITest에서 카드를 찾으려면 identifier 추가가 필요하다. 4단계에서 NavigationLink 감싸기와 함께 identifier 설정을 포함하면 7단계 UI 테스트 작성이 수월해진다.
