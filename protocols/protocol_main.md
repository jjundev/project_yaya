# iOS Protocol Main

## 목적
Yaya iOS 기능 구현 시 공통 규약을 정의한다.

## 기본 원칙
- SwiftUI + MVVM 패턴을 기본으로 한다.
- 기능 구현은 `requirements/requirement_<feature>.md` 범위를 벗어나지 않는다.
- 신규 기능은 XCTest 단위 테스트를 반드시 포함한다.
- UI 상호작용 변경이 있으면 XCUITest 작성 여부를 `UI Test Requirement` 계약으로 명시한다.

## 상태 관리
- ViewModel은 `@MainActor` 또는 메인 스레드 안전성을 보장한다.
- 장기 작업은 `Task`/`async` 흐름으로 처리하고 취소 가능성을 고려한다.

## 금지
- 비밀 키 하드코딩 금지
- 임의 스코프 확장 금지
