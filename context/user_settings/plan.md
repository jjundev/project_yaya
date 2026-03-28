# 사용자 설정 구현 계획

## 구현 범위
spec.md 기준 전체 항목을 구현한다:
- 사주 재분석 (확인 다이얼로그 → 데이터 초기화 → 온보딩 재진입)
- 알림 설정 (토글 + 시간 피커 + iOS 권한 요청 + @AppStorage 저장)
- 이용약관 / 개인정보처리방침 (Safari로 URL 열기)
- 로그아웃 확인 다이얼로그

포함하지 않는 항목 (이유 명시):
- 알림 카테고리별 분리: spec.md에서 다음 스프린트로 명시
- 앱 내 웹뷰: spec.md에서 다음 스프린트로 명시
- 계정 탈퇴: spec.md에서 다음 스프린트로 명시

## 기술 결정
| 항목 | 결정 | 이유 |
|------|------|------|
| 알림 설정 저장 | `@AppStorage` | spec.md 참고 사항에 명시. 서버 동기화 불필요한 로컬 설정이므로 UserDefaults 충분 |
| 시간 저장 형식 | `@AppStorage` + `RawRepresentable` Date 변환 | `@AppStorage`는 Date를 직접 지원하지 않으므로 TimeInterval로 저장 |
| 사주 재분석 초기화 | `FortuneViewModel.sajuAnalysis = nil` + `InvestmentViewModel.investmentProfile = nil` + `authViewModel.needsOnboarding = true` | 3개 상태를 모두 초기화해야 온보딩 완료 후 데이터 불일치가 없음. YayaApp의 기존 root navigation 로직이 `needsOnboarding`만으로 온보딩 화면 전환 처리 |
| 알림 권한 관리 | `NotificationManager` (ObservableObject) | UNUserNotificationCenter 권한 요청/상태 확인 로직을 뷰에서 분리 |
| URL 상수 | `AppConfig.swift`에 추가 | 기존 패턴(Supabase URL, API key 등)을 따름. checklist에서 하드코딩 금지 명시 |
| Safari 열기 | `Link` (SwiftUI) 또는 `openURL` environment action | NavigationLink 대신 Safari 직접 열기. `Link`가 가장 간결 |
| 로그아웃 다이얼로그 | `.alert` modifier | 기존 `authViewModel.signOut()` 재사용. checklist에서 중복 구현 금지 명시 |
| 사주 재분석 메뉴 위치 | 설정 Section 첫 번째 항목 | 설정 항목 중 가장 중요한 액션이므로 상단 배치 |

## 파일 변경 목록
### 신규 생성
- `ios/Yaya/Yaya/Views/Settings/NotificationSettingsView.swift` — 알림 on/off 토글 + 수신 시간 피커 화면
- `ios/Yaya/Yaya/Services/NotificationManager.swift` — UNUserNotificationCenter 권한 요청/상태 확인

### 수정
- `ios/Yaya/Yaya/Config/AppConfig.swift` — `termsOfServiceURL`, `privacyPolicyURL` 상수 추가
- `ios/Yaya/Yaya/Views/Common/ProfileView.swift` — 사주 재분석 항목 추가, 알림 설정 NavigationLink 대상 교체, 이용약관/개인정보처리방침을 Link로 교체, 로그아웃 확인 다이얼로그 추가

### 테스트
- `ios/Yaya/YayaTests/NotificationSettingsTests.swift` — NotificationManager 권한 로직, @AppStorage 저장 로직 단위 테스트
- `ios/Yaya/YayaUITests/ProfileSettingsUITests.swift` — 사주 재분석 다이얼로그, 로그아웃 다이얼로그, 알림 설정 화면 진입 UI 테스트

## 구현 순서
1. `AppConfig.swift`에 URL 상수 추가
2. `NotificationManager.swift` 생성 — 권한 요청/상태 확인 로직
3. `NotificationSettingsView.swift` 생성 — 토글 + 시간 피커 + 권한 거부 안내
4. `ProfileView.swift` 수정:
   a. 설정 Section에 "사주 재분석" 항목 + 확인 다이얼로그 추가
   b. "알림 설정" NavigationLink 대상을 NotificationSettingsView로 교체
   c. "이용약관"/"개인정보처리방침"을 Link(Safari)로 교체
   d. 로그아웃 버튼에 확인 다이얼로그 추가
5. 빌드 확인
6. `NotificationSettingsTests.swift` 작성 + 실행
7. `ProfileSettingsUITests.swift` 작성 + 실행
8. checklist.md 자체 점검 결과 기록

## 자체 점검 결과
- 빌드: 성공 (warning 없음)
- XCTest(단위 테스트): 9건 중 9건 통과 (재작업 후 2건 추가)
- XCUITest(UI 테스트): 8건 중 8건 통과
- Product Depth: PASS — 사주 재분석/알림 설정/이용약관/개인정보/로그아웃 전체 구현
- Functionality: PASS — 다이얼로그, 화면 전환, 토글 조작, DB 캐시 삭제 정상 동작

## 특이사항
- `FortuneViewModel`과 `InvestmentViewModel`은 `OnboardingFlowView`에서 `@StateObject`로 생성되므로, 사주 재분석 시 `needsOnboarding = true`로 전환하면 `OnboardingFlowView`가 새로 마운트되며 자동으로 새 인스턴스가 생성됨. In-memory 상태는 자동 초기화되나, Supabase DB 캐시는 별도 삭제 필요.
- 이용약관/개인정보처리방침 URL은 아직 실제 URL이 없으므로 placeholder URL을 넣되, checklist [선택] 항목에서 유효성 확인 필요.
- iOS 시뮬레이터에서 알림 권한 요청 UI가 정상 표시되나, 실제 알림 발송은 테스트하지 않음 (알림 스케줄링은 이번 scope에 없음).

### 재작업 수정 이력 (QA FAIL 대응)
- **FAIL**: 사주 재분석 시 Supabase DB 캐시(투자 프로필, 운세)가 삭제되지 않아 이전 데이터가 그대로 반환됨
- **수정**: `SupabaseService`에 `deleteInvestmentProfile(userId:)`, `deleteFortunes(userId:)` 추가. `ProfileView.resetSajuData()`에서 DB 캐시 삭제 후 `needsOnboarding = true` 설정
- **테스트**: `test_supabaseService_hasDeleteInvestmentProfile`, `test_supabaseService_hasDeleteFortunes` XCTest 2건 추가
