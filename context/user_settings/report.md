# 사용자 설정 작업 최종 보고서

## 작업 요약

ProfileView 설정 섹션에 플레이스홀더로만 존재하던 사용자 설정 기능을 완성했다. 구체적으로 사주 재분석(확인 다이얼로그 → Supabase DB 캐시 삭제 → 온보딩 재진입), 알림 설정(일일 운세 on/off 토글 + 수신 시간 피커 + iOS 권한 요청 + `@AppStorage` 영속화), 이용약관/개인정보처리방침(Safari Link), 로그아웃 확인 다이얼로그를 구현했다. 신규 파일로 `NotificationManager.swift`와 `NotificationSettingsView.swift`를 추가했고, `AppConfig.swift`, `ProfileView.swift`, `SupabaseService.swift`를 수정했다. XCTest 9건, XCUITest 8건 전체 통과, QA 최종 판정 PASS.

---

## 실수 및 수정 이력

| 항목 | 문제 내용 | 원인 | 수정 방법 |
|------|-----------|------|-----------|
| Supabase DB 캐시 미삭제 | 사주 재분석 확인 후 온보딩을 재진행해도 이전 투자 프로필·운세 데이터가 Supabase에 남아 있어 온보딩 완료 후 기존 데이터가 그대로 반환됨 | `resetSajuData()`가 `needsOnboarding = true`만 설정하고 DB 레코드를 삭제하지 않았음. In-memory `@StateObject`는 뷰 재마운트 시 자동 초기화되지만 Supabase 캐시는 별도 삭제 필요 | `SupabaseService`에 `deleteInvestmentProfile(userId:)`, `deleteFortunes(userId:)` 추가. `ProfileView.resetSajuData()`에서 두 함수를 순서대로 호출한 뒤 `needsOnboarding = true` 설정. XCTest 2건(`test_supabaseService_hasDeleteInvestmentProfile`, `test_supabaseService_hasDeleteFortunes`) 추가로 컴파일 타임 존재 검증 |
| Xcode 프로젝트 파일 미등록 | 터미널에서 신규 Swift 파일을 생성한 뒤 빌드 시 "No such module" 오류 발생 | Xcode 외부에서 생성한 파일은 `project.pbxproj`에 자동 등록되지 않음 | `python3 -m pbxproj`로 `NotificationManager.swift`, `NotificationSettingsView.swift` 두 파일을 `project.pbxproj`에 프로그래밍 방식으로 추가 |
| XCUITest 스크롤 문제 | ProfileView 설정 섹션이 화면 하단에 위치해 첫 번째 XCUITest 실행 시 모든 테스트 실패 | SwiftUI `List`는 off-screen 항목을 lazy하게 렌더링하여 XCUITest가 요소를 찾지 못함 | `scrollToElement()` 헬퍼 추가 — 요소가 `isHittable`이 될 때까지 위로 스와이프 반복 |
| `test_reanalysisDialog_confirm_navigatesToOnboarding` 실패 | 재분석 확인 후 온보딩 화면으로의 실제 이동을 XCUITest에서 검증하지 못함 | `UITEST_MAIN_TAB` 런치 환경이 `needsOnboarding` 값과 무관하게 강제로 `MainTabView`를 표시하므로, 이 모드에서는 온보딩 화면 전환 자체가 불가능 | 테스트 이름을 `test_reanalysisDialog_confirm_dismissesAlert`로 변경하여 알림 해제만 검증. E2E 플로우는 릴리스 전 수동 QA 권장으로 문서화 |

---

## 기술 결정 배경

| 항목 | 결정 | 배경 및 이유 |
|------|------|-------------|
| 알림 설정 저장 | `@AppStorage` (UserDefaults) | spec.md에서 서버 동기화 불필요한 로컬 설정으로 명시. 단순 Bool + TimeInterval 저장에 UserDefaults로 충분. `@AppStorage`는 SwiftUI binding과 자동 연동되어 별도 저장 로직 불필요 |
| 시간 저장 형식 | `TimeInterval` (`Double`) | `@AppStorage`는 `Date` 타입을 직접 지원하지 않음. `Date.timeIntervalSince1970`으로 변환하여 `Double`로 저장하고, `DatePicker` binding 시 `Date`로 재변환 |
| 사주 재분석 초기화 | Supabase DB 삭제 + `needsOnboarding = true` | In-memory ViewModel(`@StateObject`)은 `OnboardingFlowView` 재마운트 시 자동 초기화되지만, Supabase에 캐시된 `investment_profiles`, `fortunes` 레코드는 명시적 삭제 필요. 두 단계를 모두 수행해야 데이터 불일치 없음 |
| 알림 권한 관리 | `NotificationManager` (ObservableObject 분리) | `UNUserNotificationCenter` 권한 요청 및 상태 확인 로직을 뷰에서 분리. `ProfileView`와 `NotificationSettingsView` 양쪽에서 재사용 가능한 구조 확보 |
| URL 상수 위치 | `AppConfig.swift`에 추가 | 기존 Supabase URL, API key 등이 이미 `AppConfig.swift`에 상수로 관리됨. 동일 패턴 유지로 일관성 확보. checklist에서 하드코딩 금지 명시 |
| Safari 열기 방식 | SwiftUI `Link` | `NavigationLink`가 아닌 외부 URL이므로 `Link(destination:)` 사용. `openURL` environment action 대비 코드가 더 간결하고 선언적 |
| 로그아웃 다이얼로그 | `.alert` modifier + 기존 `signOut()` 재사용 | 별도 로그아웃 로직 중복 구현 금지(checklist 명시). `AuthViewModel.signOut()`이 이미 완성되어 있으므로 다이얼로그 레이어만 추가 |
| 시뮬레이터 검증 진입 | `UITEST_MAIN_TAB` 런치 환경 | OAuth 로그인을 우회하여 `MainTabView`로 직접 진입. 기존 프로젝트 XCUITest 패턴(`UITEST_MOCK_ANALYSIS` 등)과 동일한 방식으로 일관성 유지 |

---

## 특이사항 및 다음 스프린트 권장 사항

- **이용약관/개인정보처리방침 URL 미서빙**: `https://yaya.app/terms`, `https://yaya.app/privacy` URL 형식은 유효하나 실제 웹페이지가 서빙되는지 확인되지 않음. 배포 전 URL 접속 확인 필요.
- **사주 재분석 E2E XCUITest 제약**: `UITEST_MAIN_TAB` 모드는 `needsOnboarding` 값과 무관하게 항상 `MainTabView`를 표시하므로, 재분석 확인 → 온보딩 진입 전체 플로우를 XCUITest로 자동화할 수 없음. 릴리스 전 수동 QA 권장.
- **알림 스케줄링 미구현**: 알림 on/off 토글과 수신 시간 피커는 구현됐으나, 실제 로컬 알림 스케줄링(`UNUserNotificationCenter.add`)은 이번 scope에 포함되지 않음. 다음 스프린트에서 시간 설정값을 읽어 알림을 등록하는 로직 필요.
- **계정 탈퇴 미구현**: spec.md에서 다음 스프린트로 명시. ProfileView 설정 섹션에 항목 추가 및 Supabase 계정 삭제 API 연동 필요.
- **알림 카테고리 분리 미구현**: spec.md에서 다음 스프린트로 명시. 현재는 일일 운세 알림 단일 토글만 존재. 주간/월간 운세 별도 알림 설정은 추후 구현.
- **앱 내 웹뷰 미구현**: 이용약관/개인정보처리방침을 Safari가 아닌 앱 내 WKWebView로 표시하는 기능은 다음 스프린트로 명시.

---

## 회고

### 잘된 점
- Supabase DB 캐시 삭제 버그를 QA 단계에서 조기 발견하여, 실제 사용자가 데이터 불일치를 경험하기 전에 수정 완료
- `@AppStorage` 패턴으로 알림 설정 저장을 간결하게 구현하여 별도 저장 로직 없이 앱 재시작 후 설정 유지 달성
- `NotificationManager`를 ObservableObject로 분리하여 뷰와 비즈니스 로직 경계를 명확히 유지
- 기존 `signOut()`, `needsOnboarding` 등 이미 구현된 인프라를 재활용하여 코드 중복 없이 기능 완성
- XCUITest `scrollToElement()` 헬퍼로 List 스크롤 문제를 범용적으로 해결

### 개선할 점
- 외부에서 신규 파일 생성 시 `project.pbxproj` 등록을 미리 처리하지 않아 빌드 실패가 발생함. 파일 생성 직후 Xcode 프로젝트 등록을 작업 순서에 명시적으로 포함해야 함
- `UITEST_MAIN_TAB` 런치 환경의 동작 방식(항상 MainTabView 고정)을 Generator가 사전에 인지했다면, 재분석 E2E 테스트 케이스를 처음부터 현실적인 범위로 작성하여 테스트 명 변경 없이 진행할 수 있었음
- 사주 재분석 초기화 범위(In-memory vs DB)를 spec.md 또는 plan.md 작성 시점에 더 명확하게 정의했다면, Supabase 캐시 삭제 누락을 구현 단계에서 예방할 수 있었음
