# Mock 데이터 1차 표시 플랜 검토 결과

## 최종 판정: 구현 진행 가능
판정 근거: [차단] 이슈 없음. 변경 범위가 1개 함수로 제한되며, 기존 코드 파괴 위험이 없음.

## 검토 요약

| 등급 | 건수 |
|------|------|
| [차단] | 0 |
| [경고] | 1 |
| [제안] | 1 |

## 스펙 정합성 검토

### 요구사항 커버리지
- [PASS] spec.md의 모든 포함 항목(일일 운세, 주간 운세, 사주 분석 카드, 데이터 우선순위)이 plan.md 구현 범위에 포함됨 — plan.md 위치: 구현 범위
- [PASS] spec.md의 미포함 항목(Supabase 프로필, Edge Function, 캐싱)은 plan.md에 포함되지 않음 — plan.md 위치: 구현 범위 > 포함하지 않는 항목

### 범위 일탈
- [PASS] plan.md에 spec.md 근거 없는 추가 항목 없음

### 역할 월경
- [PASS] plan.md는 구현 방법만 다루며, Planner(스펙)나 Checklister(기준) 영역 침범 없음

### 테스트 포함 여부
- [PASS] XCTest 계획 3건 존재 (loadSajuAnalysis, loadDailyFortune, loadWeeklyFortune) — plan.md 위치: 테스트
- [PASS] XCUITest 계획 1건 존재 (운세 탭 진입 → 카드 표시 → 상세 화면) — plan.md 위치: 테스트

## 실행 안전성 검토

### 기존 코드 재사용
- [PASS] `AIService.shared.mockSajuAnalysis(gender:)`, `mockFortuneContent()`, `mockWeeklyFortuneContent()`를 재사용. 신규 mock 함수 작성 없음 — 확인한 파일: `ios/Yaya/Yaya/Services/AIService.swift` (lines 80, 93, 114)

### 기존 코드 파괴 위험
- [PASS] 의존성·인터페이스·DB 스키마·파일 이동/삭제 변경 없음. `loadData()` 내부 로직만 수정하며, 함수 시그니처 변경 없음 — 영향 범위: `FortuneHomeView.loadData()` (private 함수, 외부 참조 없음)

### 단계 순서의 논리성
- [PASS] 코드 수정(1) → 빌드(2) → 단위 테스트 작성(3) → 테스트 실행(4) → UI 테스트 작성(5) → 체크리스트 기록(6). 의존 순서 정상 — plan.md 구현 순서 전체

### 구체성
- [PASS] 수정 대상 파일(`FortuneHomeView.swift`), 함수(`loadData()`), 변경 내용(guard → nil-coalescing)이 명확함 — plan.md 구현 순서 1번

### 실현 가능성
- [PASS] `FortuneHomeView.loadData()` 존재 확인 — 확인한 파일: `ios/Yaya/Yaya/Views/Fortune/FortuneHomeView.swift` (line 436)
- [PASS] `FortuneHomeViewModelTests.swift` 존재 확인 — 확인한 파일: `ios/Yaya/YayaTests/FortuneHomeViewModelTests.swift`
- [PASS] `FortuneDetailUITests.swift` 존재 확인 — 확인한 파일: `ios/Yaya/YayaUITests/FortuneDetailUITests.swift`
- [PASS] `AIService.shared.mockSajuAnalysis(gender:)` 접근 가능 확인 — 기존 테스트에서 `AIService.shared.mockFortuneContent()` 호출 사용 중 (FortuneHomeViewModelTests.swift line 105)

### 하드코딩
- [PASS] fallback 날짜 `DateComponents(year: 1995, month: 1, day: 1)`는 하드코딩이나, `AIService.analyzeSaju()`가 파라미터를 무시하므로 출력에 영향 없음. 의도된 placeholder 값.

### 내부 일관성
- [PASS] 기술 결정(nil-coalescing) ↔ 구현 순서(guard 완화) ↔ 파일 변경 목록(FortuneHomeView.swift) 모두 일관됨

---

## 이슈 목록

### [경고] XCTest로 nil-fallback 경로를 직접 검증할 수 없음
- 위치: plan.md > 테스트
- 내용: `loadData()`는 `FortuneHomeView`의 `private` 함수이므로 XCTest에서 직접 호출 불가. plan.md의 단위 테스트 3건(`testLoadSajuAnalysis`, `testLoadDailyFortune`, `testLoadWeeklyFortune`)은 ViewModel 메서드 동작을 검증하지만, View 레이어의 nil-coalescing fallback 경로 자체는 검증하지 못함.
- 수정 방향: 사용자 판단. ViewModel 테스트 + 기존 XCUITest(`UITEST_MAIN_TAB=1`)로 mock 플로우 전체가 동작함을 간접 검증 가능하므로, 현 수준으로도 충분할 수 있음. 보다 엄격한 검증이 필요하면 `birthDate: nil` 사용자를 설정하는 별도 launch environment를 추가하는 방법이 있음.

### [제안] `refreshData()`에 대한 고려 명시
- 위치: plan.md > 구현 범위
- 내용: `refreshData()`(line 451)는 `loadSajuAnalysis`를 재호출하지 않고 `loadDailyFortune`·`loadWeeklyFortune`만 호출함. 초기 `loadData()`가 성공해 `sajuAnalysis`가 설정된 상태에서만 정상 동작하므로, 현재 변경에 의한 영향은 없음. 하지만 plan.md에 "refreshData()는 변경 불필요 — 이유: 초기 loadData() 성공 후에만 호출되므로 sajuAnalysis가 이미 존재함"을 명시하면 검토자 이해에 도움.
- 수정 방향: plan.md 특이사항 섹션에 한 줄 추가 (선택)
