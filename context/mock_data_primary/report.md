# Mock 데이터 1차 표시 작업 최종 보고서

## 작업 요약

Supabase 백엔드 미준비 상태에서 `FortuneHomeView.loadData()`의 guard가 사용자 프로필(`birthDate`, `gender`)의 non-nil을 요구하여 운세 화면이 빈 상태로 표시되는 문제를 해소했다. `AIService`가 이미 모든 API 호출에서 mock 데이터를 반환하는 상태였으므로, `loadData()` 내부의 nil 체크를 nil-coalescing(`??`) fallback으로 완화하는 단 1개 함수 수정으로 일일 운세 카드, 오행 분석 카드, 주간 운세 카드가 모두 정상 표시되도록 구현했다. Supabase 연동 후에는 실제 프로필 값이 non-nil이 되면 fallback이 자동으로 비활성화되어 기존 로직이 그대로 유지된다.

---

## 실수 및 수정 이력

없음 — qa.md FAIL 항목 0건.

---

## 기술 결정 배경

| 항목 | 결정 | 배경 및 이유 |
|------|------|-------------|
| fallback 방식 | nil-coalescing (`??`) | 기존 guard를 완전 제거하면 미인증 사용자도 진입 가능해지는 위험이 있음. `guard let user = authViewModel.currentUser`를 남겨 인증 방어는 유지하고, birthDate·gender의 nil만 허용하는 최소 수정. Supabase 준비 후 non-nil 값이 들어오면 `??` 우변이 평가되지 않아 dead code가 자동화됨. |
| mock 데이터 소스 | 기존 `AIService` mock 메서드 재사용 | `mockSajuAnalysis(gender:)`, `mockFortuneContent()`, `mockWeeklyFortuneContent()`가 이미 존재하고 기존 XCTest에서도 검증 완료. 신규 mock 함수 작성 없이 기존 자산 활용. |
| 변경 범위 | `FortuneHomeView.loadData()` 1개 함수 | 차단 지점이 이 함수 1곳뿐임을 코드 추적으로 확인. ViewModel·Service·Model 변경 없이 View 레이어 최소 수정으로 위험 최소화. |
| fallback 기본값 | `birthDate: 1995-01-01`, `gender: .female` | `AIService.analyzeSaju()`가 파라미터를 무시하고 mock 데이터를 반환하므로 실제 출력에 영향 없음. 의미 있는 placeholder 날짜 선택. |

---

## 특이사항 및 다음 스프린트 권장 사항

- **refreshData() 변경 불필요**: `refreshData()`(FortuneHomeView line 455)는 `loadDailyFortune`·`loadWeeklyFortune`만 호출하고 `loadSajuAnalysis`는 재호출하지 않음. 초기 `loadData()` 성공 후 `sajuAnalysis`가 이미 설정된 상태에서만 호출되므로 이번 변경에 의한 영향 없음.

- **nil-fallback 경로 XCUITest 직접 검증 미실시**: `loadData()`는 `FortuneHomeView`의 private 함수이므로 XCTest에서 직접 호출 불가. ViewModel 수준 테스트(`dailyFortune != nil`, `sajuAnalysis != nil`)와 코드 검사로 간접 검증. 더 엄격한 E2E 검증이 필요하면 `UITEST_NIL_PROFILE=1` launch environment를 추가하여 birthDate·gender가 nil인 AppUser를 세팅하는 경로를 별도 구현 권장 (다음 스프린트).

- **주간 운세 블러 표시**: free tier 사용자는 `weeklyFortune` nil 여부와 무관하게 항상 블러 미리보기 카드가 표시됨. `weeklyFortune`이 nil이면 하드코딩 fallback 텍스트("이번 주는 전반적으로 상승 기운이 흐르는...") 표시. Supabase 연동 후 실제 주간 운세가 로드되면 블러 안의 텍스트가 실제 데이터로 교체됨.

---

## 회고

### 잘된 점

- **변경 범위를 1개 함수로 제한**: 기존 코드(AIService mock, ViewModel, Model) 전체가 이미 올바르게 동작하고 있었고, 차단 지점이 FortuneHomeView.loadData() 1곳뿐임을 정확히 식별하여 최소 수정으로 문제 해소.

- **harness 파이프라인 준수**: spec → checklist → plan → review → generator → evaluator → reporter 순서를 단계 없이 이행. reviewer가 [차단] 이슈를 0건으로 확인한 후 구현에 진입하여 방향 낭비 없음.

- **빌드·테스트 즉시 통과**: 1차 수정 후 빌드 성공, 단위 테스트 54건 전체 통과. 추가 디버깅 없이 단일 사이클로 완료.

- **기존 테스트 비파괴**: 신규 코드가 기존 테스트 25건에 영향을 주지 않음.

### 개선할 점

- **View 레이어 nil-fallback의 직접 테스트 불가**: `FortuneHomeView.loadData()`가 private이라 XCTest에서 직접 검증 불가. 추후 nil 프로필 사용자 시나리오를 위한 XCUITest launch environment(`UITEST_NIL_PROFILE=1`) 추가를 설계 단계에서 함께 계획했다면 더 완결된 검증이 가능했을 것.

- **오행·주간 운세 카드 accessibilityIdentifier 미설정**: `fortune.element.card`, `fortune.weekly.card` 식별자가 없어 XCUITest에서 해당 카드를 직접 조회할 수 없음. UI 테스트 작성 시 식별자가 없어 `waitForExistence` 검증이 실질적으로 불가능한 상태. 다음 스프린트에서 식별자 추가 권장.
