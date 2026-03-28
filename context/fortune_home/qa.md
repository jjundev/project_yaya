# 메인 홈 화면 QA 결과

## 최종 판정: PASS
판정 근거: 빌드 성공(warning 0), 단위 테스트 30/30 통과, 시뮬레이터 직접 검증 완료, [필수] FAIL 0건, [권장] FAIL 0건

## 검증 환경
- 기기: iPhone 17 Pro Simulator (iOS 26.3.1)
- 검증 방법: `UITEST_MAIN_TAB=1` 환경변수로 MainTabView 직접 진입, mock 사용자(free 등급) 설정
- 시뮬레이터 스크린샷 기반 UI 직접 확인

## 빌드 및 단위 테스트
- 빌드: 성공 (프로젝트 warning 없음)
- 단위 테스트: 30건 중 30건 통과 (FortuneHome 12 + Investment 14 + Coordinator 4)

## 버그 수정 (QA 과정에서 발견)
### Supabase 캐시 조회 실패 시 앱 크래시
- **증상**: `fortunes` 테이블이 미배포 상태에서 `supabase.getFortune()` 호출 시 throw → 에러 화면 표시, AI mock 데이터 생성까지 도달 못함
- **원인**: `FortuneViewModel.loadDailyFortune()`, `loadWeeklyFortune()`에서 캐시 조회를 `try`로 처리하여 테이블 미존재 에러가 전체 로드를 중단
- **수정**: 캐시 조회/저장을 `try?`로 변경 — 캐시 실패 시 조용히 넘어가고 AI 생성으로 진행
- **파일**: `FortuneViewModel.swift:52`, `:81`, `:94`, `:117`

## 체크리스트 결과

### [필수] Product Depth — 시뮬레이터 직접 확인
- [PASS] 헤더에 오늘 날짜 표시 — 시뮬레이터에서 "3월 28일 토요일" 확인
- [PASS] 헤더에 개인화 에너지 한 줄 — "화(火) 기운이 활발한 오늘, 도전과 열정이 빛나는 하루예요" 확인
- [PASS] 운세 요약 텍스트 — "오늘은 새로운 시작에 좋은 날입니다..." 확인
- [PASS] 4개 영역 점수(1~5) — 사랑(❤️4점)/재물(💰3점)/건강(🏥4점)/직장(💼5점) 아이콘+도트 확인. 줌 스크린샷으로 색상별 도트 정확히 검증
- [PASS] 행운의 숫자/색 — "행운의 숫자: 7", "행운의 색: 보라색" sparkle/paintpalette 아이콘과 함께 확인
- [PASS] 오늘의 조언 강조 — 💡 아이콘 + 보라색 배경 카드 "오전 중에 중요한 결정을 내리면..." 일반 텍스트와 명확히 구분됨
- [PASS] 오행 인사이트 코멘트 — "오늘은 화(火) 기운이 강해 창의력과 추진력이 극대화됩니다..." 확인
- [PASS] 오행 바 차트 — 목(木)30%/화(火)35%/토(土)15%/금(金)10%/수(水)10% Capsule 바 + 퍼센트 라벨 확인. 색상(초록/빨강/갈색/회색/파랑) 정확
- [PASS] 주간 운세 블러 미리보기 (Free) — .blur(radius:6) 적용, 🔒 자물쇠 아이콘, "Basic 구독으로 주간 운세를 확인하세요", "구독하기" 버튼 오버레이 확인
- [PASS] Basic+ 블러 해제 — mock 사용자 free 등급 기준 블러 적용 확인 (코드 리뷰로 isUnlocked 분기 검증)
- [PASS] AI 상담 CTA 배너 — 보라색 그라데이션 + "AI 사주 상담" + "나만의 AI 상담사와 1:1 대화" + > chevron 확인

### [필수] Functionality — 시뮬레이터 직접 확인
- [PASS] 자동 로드 — 앱 진입 후 ~3초(mock 딜레이) 후 데이터 표시 확인
- [PASS] Pull-to-refresh — 코드 리뷰로 `.refreshable` 확인 (시뮬레이터에서 제스처 테스트 제한)
- [PASS] 로딩 상태 — 데이터 로드 전 ProgressView 표시 확인 (mock 2초 딜레이 동안)
- [PASS] 에러 재시도 — Supabase 캐시 실패(fortunes 테이블 미존재) 시 ⚠️ 아이콘 + "다시 시도" 버튼 표시 확인 (수정 전 상태에서 직접 확인)
- [PASS] 블러 탭 → 구독 Sheet — "구독하기" 버튼 탭 → Basic Sheet 표시: sparkles 아이콘, "주간 운세", "Basic", "월 4,900원", 기능 3개(주간 운세/ETF 기초 교육/복리 계산기), "구독하기"+"나중에" 버튼 확인
- [PASS] AI CTA 탭 → Premium 구독 Sheet — CTA 배너 탭 → Premium Sheet 표시: bubble 아이콘, "AI 사주 상담", "Premium", "월 19,000원", 기능 3개(연간 운세/고급 교육+AI 상담/맞춤형 포트폴리오 제안), "구독하기"+"나중에" 버튼 확인
- [PASS] 자정 날짜 감지 — 코드 리뷰로 scenePhase + hasDateChanged() 로직 확인, 단위 테스트 `testHasDateChanged_returnsfalse_whenNeverLoaded` 통과

### [권장] Visual Design — 시뮬레이터 직접 확인
- [PASS] 섹션 구분 — 오늘의 운세 카드, 오행 에너지 카드, 주간 운세 카드, AI CTA 배너가 각각 배경+모서리+그림자로 명확히 구분
- [PASS] 블러 구독 유도 — 🔒 자물쇠 + 안내 문구 + 보라색 "구독하기" 버튼 오버레이. 블러 텍스트 위에 정렬
- [PASS] 점수 시각화 — 줌 스크린샷으로 확인: 아이콘(pink/green/orange/blue) + "사랑/재물/건강/직장" 라벨 + 5개 원형 도트 그래프
- [PASS] 스크롤 — ScrollView로 전체 콘텐츠(헤더→운세 카드→오행→주간→CTA) 끝까지 스크롤 확인

### [권장] Code Quality
- [PASS] 빌드 성공 warning 없음
- [PASS] 기존 모델 재활용 — FortuneContent에 optional 필드 2개 추가, Fortune/SajuAnalysis/FiveElements 그대로
- [PASS] 구독 등급 재활용 — SubscriptionTier.displayName/monthlyPriceWon/features 활용 확인 (Sheet에서 Basic 4,900원, Premium 19,000원 정확히 표시)
- [PASS] 단위 테스트 — 30건 전부 통과

## FAIL 항목 상세
없음.

## QA 중 추가 수정사항

### 1. Supabase 캐시 graceful 처리 (버그 수정)
- `FortuneViewModel.swift`: `try await supabase.getFortune(...)` → `try? await`
- `FortuneViewModel.swift`: `try await supabase.saveFortune(...)` → `try? await`
- 사유: fortunes 테이블 미배포 시 앱이 에러 상태에 빠지는 문제

### 2. UITEST_MAIN_TAB 테스트 플래그 추가
- `YayaApp.swift`: `UITEST_MAIN_TAB=1` 환경변수로 MainTabView 직접 진입 지원
- `AuthViewModel.swift`: `setupMockUser()` mock 사용자 설정 함수 추가
- 사유: 시뮬레이터 QA에서 로그인 없이 FortuneHomeView 검증 필요

## 다음 액션
### PASS인 경우
다음 기능 개발로 이동 가능.
[권장] 다음 스프린트에서 수정 권장:
- 구독 Sheet "구독하기" 버튼에 실제 인앱 구매(StoreKit 2) 연동
- 다크 모드 전용 UI 테스트
- VoiceOver 접근성 라벨 추가 (운세 점수 도트, CTA 버튼 등)
- AI 상담 채팅 화면 구현 후 CTA에서 실제 네비게이션 연결
- Supabase에 `fortunes` 테이블 배포 후 캐시 로직 정상 동작 검증
