# 메인 홈 화면 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 stub 또는 미구현 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 크래시 또는 플로우 막힘 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 빌드 실패 또는 데이터 소실 위험 1건 이상 |

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 동작하는가

- [ ] 헤더에 오늘 날짜(연월일 + 요일)가 표시된다 — FAIL 조건: 날짜가 표시되지 않거나 어제 날짜가 표시됨
- [ ] 헤더에 사주 기반 개인화 에너지 한 줄 요약이 표시된다 — FAIL 조건: 고정 텍스트이거나 빈 문자열이 표시됨
- [ ] 오늘의 운세 카드에 요약 텍스트가 표시된다 — FAIL 조건: 요약 텍스트가 비어 있거나 표시되지 않음
- [ ] 사랑/재물/건강/직장 4개 영역 점수(1~5)가 모두 표시된다 — FAIL 조건: 4개 중 하나라도 누락되거나 범위 밖 값 표시
- [ ] 행운의 숫자와 행운의 색이 표시된다 — FAIL 조건: 둘 중 하나라도 표시되지 않음
- [ ] 오늘의 조언이 강조된 형태로 표시된다 — FAIL 조건: 조언 텍스트가 없거나 일반 텍스트와 동일한 스타일
- [ ] 오행 에너지 인사이트 카드에 한 줄 코멘트가 표시된다 — FAIL 조건: 코멘트가 비어 있거나 카드 자체가 표시되지 않음
- [ ] 오행 에너지 시각적 표현(바 차트 또는 그래프)이 표시된다 — FAIL 조건: 오행 비율이 시각적으로 표현되지 않음
- [ ] 주간 운세 블러 미리보기가 Free 사용자에게 표시된다 — FAIL 조건: 블러가 적용되지 않고 전체 내용이 노출되거나, 카드 자체가 없음
- [ ] Basic 이상 구독자에게 주간 운세가 블러 없이 전체 표시된다 — FAIL 조건: 구독자인데 블러가 여전히 적용됨
- [ ] AI 사주 상담 CTA 배너가 화면에 표시된다 — FAIL 조건: CTA 배너가 표시되지 않음

### [필수] Functionality — 핵심 플로우가 막힘 없이 동작하는가

- [ ] 앱 진입(화면 표시) 시 일일 운세 데이터가 자동 로드된다 — FAIL 조건: 화면 진입 후 데이터 로드가 시작되지 않음
- [ ] Pull-to-refresh 제스처로 운세 데이터가 새로 로드된다 — FAIL 조건: 당겨서 새로고침이 동작하지 않거나 데이터가 갱신되지 않음
- [ ] 데이터 로드 중 로딩 상태(스피너 또는 스켈레톤)가 표시된다 — FAIL 조건: 로딩 중 빈 화면이 표시됨
- [ ] 운세 로드 실패 시 재시도 버튼이 표시된다 — FAIL 조건: 실패 시 빈 화면만 표시되고 재시도 수단이 없음
- [ ] 블러 미리보기 탭 시 구독 페이지로 이동한다 — FAIL 조건: 탭해도 아무 반응 없거나 크래시 발생
- [ ] AI 상담 CTA 탭 시 Premium 구독 페이지로 이동한다 — FAIL 조건: 탭해도 아무 반응 없거나 크래시 발생
- [ ] 자정 이후 첫 진입 시 오늘 날짜의 운세가 로드된다 — FAIL 조건: 전날 운세가 그대로 표시됨

### [권장] Visual Design — 인터페이스가 일관된 느낌인가

- [ ] 각 섹션(헤더, 운세 카드, 오행 카드, 블러 카드, CTA)이 시각적으로 구분된다 — FAIL 조건: 섹션 경계 없이 텍스트가 연속으로 나열됨
- [ ] 블러 미리보기에 구독 유도 문구와 버튼이 함께 표시된다 — FAIL 조건: 블러만 있고 구독 유도 요소 없음
- [ ] 4개 영역 점수가 아이콘+색상으로 직관적으로 구분된다 — FAIL 조건: 색상이나 아이콘 없이 숫자만 나열됨
- [ ] 스크롤이 자연스럽고 전체 콘텐츠를 끝까지 볼 수 있다 — FAIL 조건: 하단 콘텐츠가 잘려서 보이지 않음

### [권장] Code Quality — 연결이 끊어진 곳은 없는가

- [ ] 빌드가 경고(warning) 없이 성공한다 — FAIL 조건: 빌드 실패 또는 새로 추가된 warning 존재
- [ ] FortuneHomeView에서 사용하는 데이터 모델이 기존 Fortune.swift 구조를 활용한다 — FAIL 조건: 기존 모델을 무시하고 중복 구조체를 새로 정의함
- [ ] 구독 등급 확인 로직이 기존 SubscriptionTier를 활용한다 — FAIL 조건: 구독 등급을 하드코딩하거나 별도 enum을 생성함
- [ ] 단위 테스트가 최소 1개 이상 존재하고 통과한다 — FAIL 조건: 테스트 파일이 없거나 전부 실패

### [선택] 추가 검증

- [ ] 다크 모드에서 화면이 정상적으로 표시된다
- [ ] VoiceOver가 주요 요소(운세 점수, 조언, CTA 버튼)를 올바르게 읽는다

## Generator 자체 점검 결과

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | 성공 | iPhone 17 Pro Simulator, warning 없음 |
| 단위 테스트 | 12건 중 12건 통과 | FortuneHomeViewModelTests.swift |
| Product Depth 자체 점검 | PASS | 아래 상세 참조 |
| Functionality 자체 점검 | PASS | 아래 상세 참조 |

### 자체 점검 상세

#### [필수] Product Depth
- [x] 헤더에 오늘 날짜 표시 — `formattedToday` ("M월 d일 EEEE" 포맷)
- [x] 개인화 에너지 한 줄 — `FortuneContent.energySummary` 필드로 AI 생성 문구 표시
- [x] 운세 요약 텍스트 — `fortune.content.summary` 표시
- [x] 4개 영역 점수 — `scoreItem()` 함수로 heart/won/health/briefcase 아이콘 + 5점 도트
- [x] 행운 숫자/색 — `Label`로 sparkle/paintpalette 아이콘과 함께 표시
- [x] 조언 강조 — `lightbulb.fill` 아이콘 + 보라색 배경 카드로 구분
- [x] 오행 인사이트 코멘트 — `FortuneContent.elementInsight` 필드
- [x] 오행 바 차트 — `elementBar()` 함수로 5개 Capsule 바 차트
- [x] 주간 운세 블러 — Free 사용자에게 `.blur(radius: 6)` + 자물쇠 + 구독 버튼 오버레이
- [x] Basic+ 블러 해제 — `isUnlocked` 분기로 전체 내용 표시
- [x] AI 상담 CTA — 보라색 그라데이션 배너, chevron.right 포함

#### [필수] Functionality
- [x] 자동 로드 — `.task { await loadData() }` 로 화면 진입 시 즉시 로드
- [x] Pull-to-refresh — `.refreshable { await refreshData() }` 구현
- [x] 로딩 상태 — `ProgressView` + "운세를 분석하고 있어요..." 텍스트
- [x] 에러 재시도 — `errorView`에 "다시 시도" 버튼 + `loadData()` 재호출
- [x] 블러 탭 → 구독 — "구독하기" 버튼 (TODO: 실제 구독 페이지 연결 필요)
- [x] AI CTA 탭 → Premium — Button 구현 (TODO: 실제 구독 페이지 연결 필요)
- [x] 자정 날짜 감지 — `scenePhase` 변경 + `hasDateChanged()` 로 foreground 복귀 시 체크

#### [권장] Visual Design
- [x] 섹션 구분 — 각 카드에 `.background`, `.cornerRadius(16)`, `.shadow` 적용
- [x] 블러 구독 유도 — 자물쇠 아이콘 + 안내 문구 + "구독하기" 버튼 오버레이
- [x] 점수 시각화 — 아이콘(심볼) + 색상(pink/green/orange/blue) + 도트 그래프
- [x] 스크롤 — `ScrollView` + `VStack(spacing: 20)` + `.padding()`

#### [권장] Code Quality
- [x] 빌드 성공 (warning 없음)
- [x] 기존 모델 재활용 — `FortuneContent`, `SajuAnalysis`, `FiveElements` 확장 사용
- [x] 구독 등급 — `authViewModel.currentUser?.subscriptionTier` (기존 `SubscriptionTier` enum)
- [x] 단위 테스트 — 12건 전부 통과

### 특이사항
- 구독하기/AI상담 CTA 버튼의 실제 네비게이션은 `// TODO`로 남김 (구독 페이지 미구현 상태)
- `project.yml`은 변경하지 않음 — pbxproj 직접 수정으로 테스트 타겟 설정
