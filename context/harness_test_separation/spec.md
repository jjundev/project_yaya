# 하네스 테스트 역할 분리 스펙

## 개요

현재 Generator와 Evaluator QA가 XCTest/XCUITest를 모두 실행하는 구조로 동일한 테스트가 두 번 실행된다.
테스트 실행 책임을 역할별로 명확히 분리하여 중복을 제거한다.
Generator는 단위 테스트 실행, QA는 UI 테스트 실행을 전담함으로써 각 역할의 독립성과 효율을 높인다.

## 범위

### 포함
- `.harness/generator.md` 수정: XCUITest 실행 책임 제거, 코드 작성은 유지
- `.harness/evaluator.md` 수정: XCTest 재실행 제거, XCUITest 실행을 QA 전담으로 명확화
- plan.md 작성 형식 수정: 자체 점검 결과에서 XCUITest 항목 제거
- checklist.md 형식 수정: XCUITest 행을 "QA 담당"으로 명시

### 미포함 (다음 스프린트)
- Reporter, Publisher 역할 변경
- Android/Espresso 테스트 역할 분리

## 사용자 스토리

### Generator 역할 변경
- Generator는 XCTest(단위 테스트)와 XCUITest(UI 테스트) 코드를 모두 작성할 수 있다
- Generator는 XCTest만 실행하고 결과를 checklist.md에 기록할 수 있다
- Generator는 XCUITest를 실행하지 않고 작업을 완료할 수 있다

### Evaluator QA 역할 변경
- QA는 Generator가 작성한 XCUITest 코드를 실행할 수 있다
- QA는 XCTest 결과를 Generator의 자체 점검 결과에서 참조할 수 있다
- QA는 XCUITest 실행 결과를 근거로 checklist 항목을 판정할 수 있다

## 완료 조건 (Definition of Done)

- [ ] generator.md에서 XCUITest 실행 문구가 제거되어 있다
- [ ] generator.md에서 XCUITest 코드 작성 책임은 유지되어 있다
- [ ] evaluator.md QA 모드에서 XCTest 재실행 절차가 제거되어 있다
- [ ] evaluator.md QA 모드에서 XCUITest 실행이 QA 전담으로 명시되어 있다
- [ ] plan.md 형식의 자체 점검 결과에 XCUITest 항목이 없다
- [ ] checklist.md 형식의 Generator 자체 점검 표에서 XCUITest가 "QA 담당"으로 표시된다

## 참고 사항
- generator.md와 evaluator.md만 수정 대상이다
- planner.md는 수정하지 않는다
- 각 .md 파일 내 다른 규칙(금지 사항, 모드 판단 등)은 변경하지 않는다
