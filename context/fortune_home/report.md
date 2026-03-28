# 메인 홈 화면 작업 최종 보고서

## 작업 요약

사주 분석 완료 후 사용자가 매일 재방문하는 메인 홈 화면(FortuneHomeView)을 전면 리팩토링했다. 개인화 헤더(날짜 + AI 생성 에너지 한 줄), 오늘의 운세 카드(4개 영역 점수·요약·조언·행운 정보), 오행 에너지 인사이트 카드(한 줄 코멘트 + 바 차트), 주간 운세 블러 미리보기(Free→블러+구독 유도, Basic+→전체 표시), AI 사주 상담 CTA 배너 5개 섹션을 구현했다. Pull-to-refresh, 에러 재시도, 자정 날짜 변경 감지, 구독 안내 Sheet(Basic/Premium 분기)를 포함한다. 투자 기능은 별도 탭으로 분리하여 이 화면에서 제외했다.

## 실수 및 수정 이력

| 항목 | 문제 내용 | 원인 | 수정 방법 |
|------|-----------|------|-----------|
| 1차 QA FAIL: 구독 버튼 no-op | "구독하기" 버튼과 AI CTA 버튼 탭 시 아무 반응 없음 (빈 `// TODO` 액션) | 초기 구현에서 구독 페이지 미구현 상태를 `// TODO` 주석만으로 처리 | `@State showSubscriptionSheet` + `.sheet` modifier로 구독 안내 Half-Sheet 구현. Basic/Premium 분기 표시 |
| Supabase 캐시 조회 크래시 | fortunes 테이블 미배포 상태에서 `supabase.getFortune()` throw → 에러 화면 표시, AI mock 데이터 생성 미도달 | `loadDailyFortune()`에서 캐시 조회를 `try`로 처리하여 테이블 미존재 에러가 전체 로드 중단 | 캐시 조회/저장을 `try?`로 변경 — 캐시 실패 시 조용히 넘어가고 AI 생성으로 진행 |
| XcodeGen SPM 패키지 삭제 | `xcodegen generate` 실행 시 GoogleSignIn, KakaoSDK SPM 패키지 참조가 제거됨 | project.yml에 SPM 패키지가 정의되지 않은 상태에서 XcodeGen이 pbxproj를 덮어씀 | project.yml 변경 대신 pbxproj 직접 수정으로 전환. `git checkout`으로 원복 후 수동 편집 |
| 테스트 타겟 Info.plist 누락 | `xcodebuild test` 실행 시 "Cannot code sign because the target does not have an Info.plist" 에러 | YayaTests 빌드 설정에 `GENERATE_INFOPLIST_FILE = YES` 미설정 | pbxproj의 YayaTests Debug/Release 빌드 설정에 해당 플래그 직접 추가 |
| origin/main 머지 충돌 | 워크트리 생성 이후 origin/main에 PR #6, #7이 머지되어 pbxproj 충돌 | 워크트리 브랜치가 origin/main 대비 4커밋 뒤처진 상태 | 양쪽 변경사항(FortuneHomeViewModelTests + InvestmentOnboardingTests + OnboardingAnalysisCoordinatorTests) 모두 유지하는 방향으로 충돌 해결 |

## 기술 결정 배경

| 항목 | 결정 | 배경 및 이유 |
|------|------|-------------|
| 에너지 한 줄 데이터 | `FortuneContent`에 `energySummary` optional 필드 추가 | AI가 운세 생성 시 함께 생성하는 구조. Edge Function 미배포 상태이므로 optional로 추가하여 기존 API 응답과 하위 호환 유지 |
| 오행 인사이트 문구 | `FortuneContent`에 `elementInsight` optional 필드 추가 | 오늘 기운과 사주 오행의 관계를 AI가 매일 생성. optional이므로 기존 데이터 디코딩에 영향 없음 |
| 주간 운세 블러 | SwiftUI `.blur(radius: 6)` modifier + ZStack overlay | SwiftUI 기본 제공으로 추가 라이브러리 불필요. 자물쇠 아이콘 + 안내 문구 + 구독 버튼을 ZStack으로 오버레이 |
| 구독 등급 확인 | 기존 `SubscriptionTier` enum 비교 연산 | `displayName`, `monthlyPriceWon`, `features` 속성이 이미 정의되어 있어 Sheet에서 그대로 활용. 별도 구독 모델 불필요 |
| 구독 네비게이션 | `.sheet` + `.presentationDetents([.medium])` Half-Sheet | 실제 구독 페이지(StoreKit 2) 미구현 상태에서 임시 Sheet로 구독 안내. 1차 QA FAIL 후 추가된 결정 |
| 날짜 변경 감지 | `scenePhase` + `lastLoadedDate` 비교 | foreground 복귀 시 날짜 비교로 자정 넘김 감지. Timer 대비 배터리 효율적 |
| 테스트 타겟 설정 | pbxproj 직접 수정 (XcodeGen 미사용) | project.yml에 SPM 패키지가 미등록 상태라 XcodeGen 실행 시 기존 패키지 참조가 삭제됨. 안전하게 pbxproj만 수동 편집 |
| Supabase 캐시 처리 | `try?`로 graceful 처리 | fortunes 테이블 미배포 시 캐시 조회 실패가 전체 운세 로드를 중단시키는 버그. 캐시는 선택적 최적화이므로 실패해도 AI 생성으로 진행해야 함 |

## 특이사항 및 다음 스프린트 권장 사항

- **Edge Function 미배포**: 모든 사주 분석/운세 생성 데이터가 AIService mock으로 동작. Edge Function 배포 후 실제 AI 생성 데이터로 전환 필요
- **fortunes 테이블 미배포**: Supabase에 테이블이 없어 캐시 로직이 `try?`로 우회 중. 테이블 배포 후 캐시 정상 동작 검증 필요
- **인앱 구매 미연동**: 구독 Sheet의 "구독하기" 버튼이 Sheet 닫기만 수행. StoreKit 2 인앱 구매 연동 필요
- **AI 상담 채팅 미구현**: CTA 배너가 Premium 구독 Sheet만 표시. 실제 AI 채팅 화면 구현 후 네비게이션 연결 필요
- **다크 모드 미검증**: 시스템 색상(`Color(.systemBackground)` 등) 사용으로 대부분 대응되나, 시뮬레이터에서 다크 모드 전용 테스트 미실시
- **VoiceOver 접근성**: 점수 도트, 오행 바 차트, CTA 버튼 등에 접근성 라벨 미추가
- **UITEST_MAIN_TAB 플래그**: QA 과정에서 시뮬레이터 검증용으로 추가. 향후 UI 테스트 자동화에 활용 가능

## 회고

### 잘된 점
- **harness 사이클 완주**: planner → evaluator checklist → generator → evaluator qa(FAIL) → generator 재작업 → evaluator qa(PASS) → 시뮬레이터 검증까지 전체 사이클을 완수함
- **1차 QA FAIL의 조기 발견**: 구독 버튼 no-op 문제를 QA에서 즉시 포착하고 Sheet 기반 임시 해결로 빠르게 수정
- **기존 모델 재활용**: Fortune, SajuAnalysis, FiveElements, SubscriptionTier 등 기존 모델을 최대한 활용하여 코드 중복 없이 구현
- **시뮬레이터 직접 검증**: 코드 리뷰만으로는 발견하지 못한 Supabase 캐시 크래시 버그를 시뮬레이터 실행으로 발견·수정
- **origin/main 머지 충돌 해결**: 워크트리 작업 중 상위 브랜치 변경사항을 안전하게 병합하여 테스트 파일 누락 없이 통합

### 개선할 점
- **XcodeGen/pbxproj 관리 전략 부재**: project.yml과 pbxproj 간 불일치(SPM 패키지 미등록)로 XcodeGen을 쓸 수 없었음. project.yml에 SPM 패키지를 등록하는 작업이 선행되어야 함
- **Supabase 테이블 의존성 사전 확인 부족**: fortunes 테이블 미존재 상태를 개발 초기에 파악했다면, 처음부터 `try?`로 처리했을 것. 백엔드 상태를 구현 전에 확인하는 습관 필요
- **시뮬레이터 테스트 환경 미비**: MainTabView 직접 진입을 위한 `UITEST_MAIN_TAB` 플래그가 QA 도중에야 추가됨. 향후 테스트 인프라를 generator 단계에서 미리 구축하면 QA 효율 향상
