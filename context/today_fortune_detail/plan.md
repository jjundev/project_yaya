# 오늘의 운세 상세 화면 구현 계획

## 구현 범위
spec.md 기준으로 이번에 구현할 항목:
- FortuneHomeView 오늘의 운세 카드 탭 → 상세 화면 네비게이션
- 상세 화면: 헤더(날짜 + 요약), 영역별 상세 해설 4개, AI 개인화 메시지, 행운 아이템, 공유 버튼
- FortuneContent 모델에 영역별 해설 + 개인화 메시지 필드 추가
- Mock 데이터 업데이트
- 로딩/빈 상태 처리

포함하지 않는 항목 (이유 명시):
- 행운의 방향·시간대: spec.md "포함"에 명시되어 있으나, "미포함"에도 "데이터 모델 추가 → 별도 스프린트"로 기재되어 **스펙 자체에 모순이 존재**한다. FortuneContent에 해당 필드가 없으므로 이번 스프린트에서는 숫자·색만 구현하고, 방향·시간대는 다음 스프린트에서 모델 추가 후 구현한다.
- 공유 이미지 커스터마이징: spec.md "미포함"에 명시

## 기술 결정
| 항목 | 결정 | 이유 |
|------|------|------|
| 네비게이션 방식 | NavigationLink (push) | FortuneHomeView가 이미 NavigationStack 사용 중, 뒤로가기 자동 지원 |
| 영역별 해설 데이터 | FortuneContent에 optional 필드 5개 추가 | 기존 패턴(energySummary, elementInsight)과 동일, 하위 호환 보장 |
| 공유 기능 | ShareLink (iOS 16+) | 앱 최소 타겟 iOS 17, 시스템 공유 시트 자동 호출 |
| 점수 시각화 | FortuneDetailView 내에 도트 5개 로컬 함수 구현 | FortuneHomeView.scoreItem은 private이므로 직접 호출 불가. 동일 패턴을 FortuneDetailView 내부에 별도 구현하여 일관성 유지 |
| 프로젝트 파일 등록 | 불필요 | XcodeGen(project.yml)이 Yaya 디렉토리 자동 포함 |

## 파일 변경 목록
### 신규 생성
- `ios/Yaya/Yaya/Views/Fortune/FortuneDetailView.swift` — 오늘의 운세 상세 화면

### 수정
- `ios/Yaya/Yaya/Models/Fortune.swift` — FortuneContent에 영역별 해설 + 개인화 메시지 필드 추가
- `ios/Yaya/Yaya/Views/Fortune/FortuneHomeView.swift` — dailyFortuneCard를 NavigationLink로 감싸기
- `ios/Yaya/Yaya/Services/AIService.swift` — mockFortuneContent()에 신규 필드 데이터 추가

### 테스트
- `ios/Yaya/YayaTests/FortuneDetailTests.swift` — 상세 화면 데이터 바인딩, FortuneContent 신규 필드 디코딩, 공유 텍스트 생성 단위 테스트
- `ios/Yaya/YayaUITests/FortuneDetailUITests.swift` — 홈 → 상세 진입, 섹션 표시, 뒤로가기 UI 테스트

## 구현 순서

### 1단계: FortuneContent 모델 확장
`Fortune.swift`의 `FortuneContent`에 optional 필드 5개 추가:
- `loveDetail: String?` — 사랑운 AI 해설 (2~4문장)
- `moneyDetail: String?` — 재물운 AI 해설
- `healthDetail: String?` — 건강운 AI 해설
- `workDetail: String?` — 직장운 AI 해설
- `personalMessage: String?` — AI 개인화 편지

CodingKeys에 snake_case 매핑 추가. 기존 JSON 디코딩 하위 호환 유지 (optional이므로).

### 2단계: Mock 데이터 업데이트
`AIService.swift`의 `mockFortuneContent()`에 5개 신규 필드 mock 값 추가.

### 3단계: FortuneDetailView 생성
`Views/Fortune/FortuneDetailView.swift` 신규 작성.

구조:
```
ScrollView
├─ 헤더: 날짜 + energySummary (요약)
├─ 영역별 상세 섹션 (4개 카드)
│  ├─ 사랑운: 아이콘 + 점수 도트 + loveDetail 텍스트
│  ├─ 재물운: 아이콘 + 점수 도트 + moneyDetail 텍스트
│  ├─ 건강운: 아이콘 + 점수 도트 + healthDetail 텍스트
│  └─ 직장운: 아이콘 + 점수 도트 + workDetail 텍스트
├─ AI 개인화 메시지 (편지 스타일 카드)
│  └─ personalMessage 텍스트
├─ 행운 아이템 (숫자 + 색)
└─ 공유 버튼 (ShareLink)
```

데이터 소스: `@EnvironmentObject var fortuneVM: FortuneViewModel` → `fortuneVM.dailyFortune` 재사용.
빈 상태: `dailyFortune == nil`일 때 안내 메시지 표시.

### 4단계: FortuneHomeView 네비게이션 연결
`dailyFortuneCard`를 `NavigationLink(destination: FortuneDetailView()) { ... }` 로 감싸기.
buttonStyle(.plain) 적용하여 기존 카드 스타일 유지.
dailyFortuneCard에 `.accessibilityIdentifier("fortune.daily.card")` 추가 (XCUITest에서 탭 대상 식별용).

### 5단계: 빌드 확인
`make build` 또는 xcodebuild로 빌드 성공 확인.

### 6단계: 단위 테스트 작성 및 실행
`FortuneDetailTests.swift` 작성:
- FortuneContent 신규 필드 JSON 디코딩 테스트 (with / without 신규 필드)
- Mock 데이터에 신규 필드 존재 확인
- 공유 텍스트 포맷 검증

`make test-unit` 또는 `make test-quick` 실행.

### 7단계: UI 테스트 작성 (실행은 QA)
`FortuneDetailUITests.swift` 작성:
- 진입 방식: `launchEnvironment["UITEST_MAIN_TAB"] = "1"` 설정하여 MainTabView로 직접 진입 (로그인/온보딩 우회)
- 홈에서 오늘의 운세 카드(`fortune.daily.card`) 탭 → 상세 화면 진입 확인
- 상세 화면에서 영역별 섹션 4개 존재 확인
- AI 개인화 메시지 섹션 존재 확인
- 행운 아이템 표시 확인
- 뒤로가기 → 홈 복귀 확인

### 8단계: checklist.md 자체 점검

## 자체 점검 결과

- 빌드: 성공 (warning 없음)
- XCTest(단위 테스트): 51건 중 51건 통과 (신규 FortuneDetailTests 10건 포함)
- Product Depth: PASS — [필수] 10개 항목 모두 구현 (카드 탭 진입, 헤더, 영역별 4개 섹션, AI 메시지, 숫자/색, 공유)
- Functionality: PASS — [필수] 4개 항목 모두 구현 (뒤로가기, 빈 상태, nil 안전, 데이터 재사용)

## 특이사항
- FortuneContent에 optional 필드 5개 추가 시 기존 Supabase 테이블/Edge Function과의 호환성 주의. 모두 optional이므로 하위 호환 보장됨.
- 현재 모든 데이터가 mock 상태이므로 실제 AI 생성 시 prompt에 영역별 해설 + 개인화 편지 포함 필요 (다음 스프린트).
- spec.md 행운 아이템 범위 모순: "포함"에 방향·시간대 명시 ↔ "미포함"에 데이터 모델 추가 불가. 이번 스프린트는 숫자·색만 구현, 방향·시간대는 FortuneContent 모델 확장 후 다음 스프린트에서 구현.
- FortuneHomeView.scoreItem은 private이므로 FortuneDetailView에서 동일 패턴의 로컬 함수를 별도 구현한다.

### 재작업 (qa.md 기반)
- **XCUITest 접근성 수정**: FortuneDetailView의 VStack/HStack 컨테이너 4곳에 `.accessibilityElement(children: .contain)` 추가. SwiftUI VStack/HStack은 기본적으로 접근성 트리에 단일 요소로 노출되지 않아 `app.otherElements[...]`로 검색 불가했던 문제 해결.
  - `headerSection` (VStack)
  - `scoreDetailCard` (VStack) — 4개 카드 모두 적용
  - `personalMessageSection` (VStack, Group 내부)
  - `luckyItemsSection` (HStack)
- 빌드: 성공 (warning 없음)
- XCTest: 51건 전체 통과 (기존 결과와 동일)
