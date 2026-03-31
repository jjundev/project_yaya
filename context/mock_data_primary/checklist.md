# Mock 데이터 1차 표시 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 stub 또는 미구현 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 크래시 또는 플로우 막힘 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 빌드 실패 또는 데이터 소실 위험 1건 이상 |

---

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 동작하는가

- [ ] Supabase 미연동 상태에서 운세 탭 진입 시 로딩 인디케이터가 표시된다
  — FAIL 조건: 로딩 없이 즉시 빈 화면 또는 에러 메시지가 표시됨

- [ ] 로딩 완료 후 오늘의 운세 카드가 홈 화면에 표시된다
  — FAIL 조건: `dailyFortune == nil`인 채로 빈 카드 또는 "아직 운세가 준비되지 않았어요" 문구 표시

- [ ] 오늘의 운세 카드에 사랑·재물·건강·직업 점수(1~5)가 표시된다
  — FAIL 조건: 점수 항목 중 하나라도 0 또는 미표시

- [ ] 오늘의 운세 카드를 탭하면 FortuneDetailView로 이동한다
  — FAIL 조건: 탭 후 화면 전환 없음, 또는 전환 후 "아직 오늘의 운세가 준비되지 않았어요" 빈 화면 표시

- [ ] FortuneDetailView에서 운세 요약 텍스트와 각 영역별 상세 내용이 표시된다
  — FAIL 조건: 텍스트 영역이 비어 있거나 nil로 표시됨

- [ ] 오행 분석 카드(목·화·토·금·수 비율)가 홈 화면에 표시된다
  — FAIL 조건: `sajuAnalysis == nil`로 카드 미노출

- [ ] 주간 운세 카드가 홈 화면에 표시된다
  — FAIL 조건: `weeklyFortune == nil`로 카드 미노출 또는 블러 처리 없이 빈 상태

### [필수] Functionality — 핵심 플로우가 막힘 없이 동작하는가

- [ ] 운세 탭 진입 시 앱이 크래시 없이 동작한다
  — FAIL 조건: `Thread 1: Fatal error` 또는 비정상 종료 발생

- [ ] `birthDate == nil`인 사용자로 loadData() 호출 시 early return 없이 정상 진행된다
  — FAIL 조건: `dailyFortune`이 loadData() 호출 후에도 nil로 유지됨 (XCTest: `XCTAssertNotNil(fortuneVM.dailyFortune)`)

- [ ] `gender == nil`인 사용자로 loadData() 호출 시 early return 없이 정상 진행된다
  — FAIL 조건: `sajuAnalysis`가 loadData() 호출 후에도 nil로 유지됨 (XCTest: `XCTAssertNotNil(fortuneVM.sajuAnalysis)`)

- [ ] pull-to-refresh 동작 시 운세가 다시 로드된다
  — FAIL 조건: 새로고침 후 화면이 빈 상태로 전환되거나 기존 데이터가 사라짐

- [ ] 앱을 백그라운드 전환 후 복귀 시 운세 화면이 그대로 유지된다
  — FAIL 조건: 복귀 후 빈 화면으로 초기화됨

### [권장] Visual Design — 인터페이스가 일관된 느낌인가

- [ ] 로딩 중에는 NavigationLink(운세 카드)가 표시되지 않는다
  — FAIL 조건: 로딩 스피너와 운세 카드가 동시에 노출됨

- [ ] FortuneDetailView 상단에 "오늘의 운세" 타이틀과 뒤로가기 버튼이 표시된다
  — FAIL 조건: 네비게이션 타이틀 누락 또는 뒤로가기 불가

- [ ] 운세 카드의 점수 시각화(별·바 등)가 0점으로 표시되지 않는다
  — FAIL 조건: mock 점수(loveScore:4, moneyScore:3 등)가 0으로 렌더링됨

### [권장] Code Quality — 연결이 끊어진 곳은 없는가

- [ ] `birthDate`·`gender`가 non-nil인 정상 사용자 프로필로도 기존과 동일하게 동작한다
  — FAIL 조건: nil-coalescing fallback 값이 non-nil 프로필에서도 적용됨

- [ ] Supabase getFortune/saveFortune 실패가 화면 오류로 노출되지 않는다
  — FAIL 조건: "운세를 불러오는데 실패했습니다" 에러 메시지가 표시됨

- [ ] 빌드 경고(Warning) 없이 컴파일된다
  — FAIL 조건: 신규 코드에 기인한 Swift 컴파일 경고 발생

### [선택] 추가 검증

- [ ] 날짜가 바뀐 후(자정 이후) 앱 포그라운드 복귀 시 운세가 재로드된다
- [ ] 여러 번 탭 전환(운세 → 투자성향 → 운세)을 반복해도 운세 데이터가 유지된다

---

## Generator 자체 점검 결과

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | ✅ 성공 | `BUILD SUCCEEDED`, 신규 코드 기인 경고 0건 (기존 AppIntents 경고 1건만 존재) |
| XCTest(단위 테스트) | ✅ 54건 전체 통과 | 신규 3건 통과: `testLoadSajuAnalysis_setsSajuAnalysis`, `testLoadDailyFortune_setsDailyFortune`, `testLoadWeeklyFortune_setsWeeklyFortune` |
| XCUITest(UI 테스트) | 작성 완료 (QA 실행 대기) | `testMockUser_fortuneFlowEndToEnd` — 카드 3종 표시 + 상세 전환 검증 |
| Product Depth 자체 점검 | ✅ PASS | `loadData()`의 guard 완화로 `birthDate`·`gender` nil 시에도 mock 운세 로드 진행. `sajuAnalysis`, `dailyFortune`, `weeklyFortune` 모두 non-nil 확인 (XCTest 검증 완료) |
| Functionality 자체 점검 | ✅ PASS | nil-coalescing fallback이 동작하며, `AIService` mock이 정상 반환. non-nil 프로필 사용자는 `??` 연산자가 평가되지 않아 기존 동작 유지 |
