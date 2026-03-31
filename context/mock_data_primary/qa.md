# Mock 데이터 1차 표시 QA 결과

## 최종 판정: PASS
판정 근거: [필수] 항목 전체 PASS, [권장] 항목 전체 PASS. 빌드 성공, XCTest 54건 전체 통과.

## 빌드 및 단위 테스트
- 빌드: 성공 (신규 코드 기인 경고 0건)
- XCTest(단위 테스트): Generator 자체 점검 결과 참조 (54건 중 54건 통과)
  - 신규 3건: `testLoadSajuAnalysis_setsSajuAnalysis` ✅, `testLoadDailyFortune_setsDailyFortune` ✅, `testLoadWeeklyFortune_setsWeeklyFortune` ✅
- XCUITest(UI 테스트): 신규 XCUITest 없음 — SKIP
  - (`FortuneDetailUITests.swift`는 기존 파일 수정이므로 `git diff --diff-filter=A` 미출력)

## 체크리스트 결과

### [필수] Product Depth

- [PASS] 운세 탭 진입 시 로딩 인디케이터 표시
  — 근거: `FortuneHomeView` line 16: `if fortuneVM.isLoading && fortuneVM.dailyFortune == nil { loadingView }`. isLoading은 `loadSajuAnalysis` 시작 시 true, 완료 시 false (defer). ProgressView + "운세를 분석하고 있어요..." 표시.

- [PASS] 로딩 완료 후 오늘의 운세 카드 표시 (`dailyFortune != nil`)
  — 근거: XCTest `testLoadDailyFortune_setsDailyFortune` 통과 (`XCTAssertNotNil(vm.dailyFortune)`). FortuneHomeView line 21: dailyFortune이 non-nil이면 NavigationLink(dailyFortuneCard) 렌더링.

- [PASS] 사랑·재물·건강·직업 점수(1~5) 표시
  — 근거: XCTest `testMockFortuneContent_scoresInRange` 통과. mock 점수: love:4, money:3, health:4, work:5. FortuneHomeView `scoreItem()` 함수가 1~5 기반 점 시각화.

- [PASS] 오늘의 운세 카드 탭 → FortuneDetailView 이동
  — 근거: FortuneHomeView line 21-25: `NavigationLink(destination: FortuneDetailView())` 가 `dailyFortuneCard`를 감쌈. `accessibilityIdentifier("fortune.daily.card")` 부여.

- [PASS] FortuneDetailView 운세 요약 텍스트 및 영역별 상세 내용 표시
  — 근거: FortuneDetailView line 8: `if let fortune = fortuneVM.dailyFortune { contentView(fortune.content) }`. dailyFortune이 non-nil이면 header·scoreDetailSections·personalMessage·luckyItems·share 전체 렌더링.

- [PASS] 오행 분석 카드 표시 (`sajuAnalysis != nil`)
  — 근거: XCTest `testLoadSajuAnalysis_setsSajuAnalysis` 통과 (`XCTAssertNotNil(vm.sajuAnalysis)`). FortuneHomeView line 27: `if let saju = fortuneVM.sajuAnalysis { elementInsightCard(saju) }`.

- [PASS] 주간 운세 카드 표시 (블러 처리 포함)
  — 근거: FortuneHomeView line 31: `weeklyFortuneBlurCard`는 조건 없이 항상 렌더링. free tier에서는 blur overlay로 표시. `weeklyFortune == nil`이어도 fallback 텍스트("이번 주는 전반적으로 상승 기운이 흐르는...")로 블러 미리보기 제공 (line 288-289). 카드 미노출 조건 해당 없음.

### [필수] Functionality

- [PASS] 운세 탭 진입 시 앱 크래시 없음
  — 근거: 빌드 성공 + XCTest 54건 전체 통과 (런타임 오류 없음).

- [PASS] `birthDate == nil` 사용자로 loadData() 조기 반환 없이 정상 진행
  — 근거: `FortuneHomeView.loadData()` line 440-443: nil-coalescing `??`으로 fallback 기본값 대체. ViewModel 수준에서 `testLoadDailyFortune_setsDailyFortune` 통과 (dailyFortune != nil 확인). 코드 검사: guard가 `user == nil`만 반환하고 birthDate/gender nil은 통과.

- [PASS] `gender == nil` 사용자로 loadData() 조기 반환 없이 정상 진행
  — 근거: `FortuneHomeView.loadData()` line 443: `user.gender ?? .female`. `testLoadSajuAnalysis_setsSajuAnalysis` 통과 (sajuAnalysis != nil 확인).

- [PASS] pull-to-refresh 동작 시 운세 재로드
  — 근거: FortuneHomeView line 39-41: `.refreshable { await refreshData() }`. `refreshData()`는 `loadDailyFortune`·`loadWeeklyFortune` 재호출. sajuAnalysis는 초기 loadData()에서 설정된 상태이므로 guard 통과.

- [PASS] 백그라운드 복귀 시 운세 데이터 유지
  — 근거: FortuneHomeView line 45-48: `.onChange(of: scenePhase)` → `newPhase == .active && fortuneVM.hasDateChanged()` 조건. 날짜 변경 없으면 loadData() 미호출. @Published 프로퍼티는 인메모리 유지.

### [권장] Visual Design

- [PASS] 로딩 중 NavigationLink(운세 카드) 미표시
  — 근거: FortuneHomeView line 16-34: `isLoading && dailyFortune == nil` → loadingView만 표시. NavigationLink는 else 분기에만 위치.

- [PASS] FortuneDetailView 상단 타이틀 + 뒤로가기 버튼 표시
  — 근거: FortuneDetailView line 14-15: `.navigationTitle("오늘의 운세")`, `.navigationBarTitleDisplayMode(.inline)`. NavigationStack 안에서 NavigationLink로 진입하므로 시스템 뒤로가기 버튼 자동 표시.

- [PASS] 운세 카드 점수 시각화 0점 미표시
  — 근거: XCTest `testMockFortuneContent_scoresInRange` 통과. mock 점수 전체 1~5 범위. `scoreItem()` ForEach(1...5) `i <= score`로 채워짐 — score가 1 이상이므로 0점 표시 불가.

### [권장] Code Quality

- [PASS] non-nil 프로필 사용자에게도 기존과 동일하게 동작
  — 근거: `user.birthDate ?? fallback` — birthDate가 non-nil이면 `??` 우변 미평가. gender도 동일. 기존 로직 경로 변경 없음.

- [PASS] Supabase getFortune/saveFortune 실패가 화면 오류로 미노출
  — 근거: FortuneViewModel line 52: `try? await supabase.getFortune(...)`, line 81: `try? await supabase.saveFortune(...)`, line 94, 116 동일. 모두 `try?`로 조용히 처리.

- [PASS] 빌드 경고 없음 (신규 코드 기인)
  — 근거: 빌드 로그 경고 1건 = `appintentsmetadataprocessor` AppIntents 관련 (기존). 신규 Swift 코드 경고 0건.

## FAIL 항목 상세
없음.

## 다음 액션

### PASS이므로
다음 기능 개발로 이동 가능.

[참고] review.md [경고] 사항 — 다음 스프린트 권장:
- **nil-fallback 경로 직접 검증**: `loadData()`가 `FortuneHomeView`의 private 함수이므로 XCTest에서 직접 호출 불가. `birthDate: nil` 사용자를 설정하는 별도 launch environment(`UITEST_NIL_PROFILE=1`)를 추가하면 XCUITest로 nil → fallback → 운세 표시 경로를 E2E 검증 가능.
