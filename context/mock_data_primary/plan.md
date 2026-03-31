# Mock 데이터 1차 표시 구현 계획

## 구현 범위
spec.md 기준으로 이번에 구현할 항목:
- 사용자 프로필(birthDate·gender)이 nil일 때 mock 기본값으로 fallback하여 운세 로드
- 일일 운세, 주간 운세, 사주 분석 카드가 모두 정상 표시

포함하지 않는 항목 (이유 명시):
- Supabase 사용자 프로필 저장/조회 수정: Supabase 미준비 상태이므로 이번 범위 아님
- Edge Function 배포: 다음 스프린트
- 운세 캐싱(DB fortunes 테이블): Supabase 준비 후 자연스럽게 동작

## 기술 결정
| 항목 | 결정 | 이유 |
|------|------|------|
| fallback 방식 | nil-coalescing (`??`) | 기존 코드 1곳만 수정, Supabase 준비 시 dead code 자동화 |
| mock 데이터 소스 | 기존 `AIService` mock 메서드 재사용 | 이미 검증된 mock 데이터 존재 |
| 변경 범위 | `FortuneHomeView.loadData()` 1개 함수 | 최소 변경으로 차단 지점 해소 |

## 파일 변경 목록
### 신규 생성
- 없음

### 수정
- `ios/Yaya/Yaya/Views/Fortune/FortuneHomeView.swift` — `loadData()` guard 완화 (birthDate·gender nil 시 fallback 기본값 사용)

### 테스트
- `ios/Yaya/YayaTests/FortuneHomeViewModelTests.swift` — `loadSajuAnalysis`·`loadDailyFortune`·`loadWeeklyFortune` mock 호출 통합 테스트 추가
- `ios/Yaya/YayaUITests/FortuneDetailUITests.swift` — mock 사용자로 운세 탭 진입 → 카드 표시 → 상세 화면 전환 UI 테스트 추가 (실행은 QA 담당)

## 구현 순서
1. `FortuneHomeView.swift`의 `loadData()` 수정: `birthDate`·`gender` guard를 nil-coalescing fallback으로 변경
2. 빌드 실행 (`make build`) — 컴파일 성공 확인
3. `FortuneHomeViewModelTests.swift`에 단위 테스트 추가:
   - `testLoadSajuAnalysis_setsSajuAnalysis`: mock 사주 분석 로드 후 `sajuAnalysis != nil` 검증
   - `testLoadDailyFortune_setsDailyFortune`: mock 일일 운세 로드 후 `dailyFortune != nil` 검증
   - `testLoadWeeklyFortune_setsWeeklyFortune`: mock 주간 운세 로드 후 `weeklyFortune != nil` 검증
4. XCTest 실행 (`make test-unit`) — 전체 통과 확인
5. `FortuneDetailUITests.swift`에 UI 테스트 추가 (작성만, 실행은 QA 담당):
   - mock 사용자로 앱 진입 → 운세 카드 표시 확인 → 카드 탭 → 상세 화면 내용 확인
6. `checklist.md` 자체 점검 결과 기록

## 자체 점검 결과
- 빌드: 성공 (신규 코드 경고 0건)
- XCTest(단위 테스트): 54건 중 54건 통과 (신규 3건 포함)
- Product Depth: PASS — `sajuAnalysis`, `dailyFortune`, `weeklyFortune` 모두 non-nil 검증 완료
- Functionality: PASS — nil-coalescing fallback 동작 확인, non-nil 프로필 영향 없음

## 특이사항
- `AIService.analyzeSaju()`는 파라미터(birthDate, gender 등)를 무시하고 mock 데이터를 반환하므로, fallback 기본값의 실제 값은 출력에 영향 없음
- Supabase 연동 후 `birthDate`·`gender`가 non-nil이 되면 `??` 연산자의 fallback은 평가되지 않아 기존 동작이 그대로 유지됨
