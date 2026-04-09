# iOS Testing Protocol

## Unit Test (XCTest)
- 핵심 비즈니스 로직과 ViewModel 상태 전이는 XCTest로 검증한다.
- Given/When/Then 구조를 권장한다.

## UI Test (XCUITest)
- 화면 전환/입력/버튼 탭 등 사용자 인터랙션 회귀는 XCUITest로 검증한다.
- 테스트 실행은 기본적으로 `make test-ui` 또는 `make test-ui-branch`를 사용한다.

## UI Test Requirement Contract
다음 섹션을 `implement-plan.md`, `review-checklist.md`에 포함한다.
- Required: YES|NO
- Reason
- Trigger IDs
- XCUITest Paths (legacy: AndroidTest Paths 허용)
- Test Filter
