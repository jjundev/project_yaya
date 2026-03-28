# 하네스 테스트 역할 분리 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 미수정 또는 누락 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 규칙 충돌 또는 모순 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 문서 파싱 불가 또는 형식 오류 1건 이상 |

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 반영되었는가

- [ ] generator.md 구현 모드의 구현 순서에서 XCUITest 실행 문구가 제거되어 있다 — FAIL 조건: "XCUITest 실행"이라는 문구가 구현 순서에 남아 있는 경우
- [ ] generator.md 구현 모드의 구현 순서에서 XCUITest 코드 작성 책임은 유지되어 있다 — FAIL 조건: XCUITest 코드 작성 자체가 제거된 경우
- [ ] generator.md 금지 사항에서 "UI 인터랙션 검증이 필요한 기능임에도 XCUITest 없이 작업을 종료하지 않는다" 항목이 제거되어 있다 — FAIL 조건: 해당 문구가 그대로 남아 있는 경우
- [ ] generator.md 금지 사항에 "XCUITest를 직접 실행하지 않는다 (실행은 QA 담당)" 취지의 문구가 추가되어 있다 — FAIL 조건: 해당 취지의 문구가 없는 경우
- [ ] evaluator.md QA 모드 테스트 절차에서 XCTest(단위 테스트) 재실행 단계가 제거되어 있다 — FAIL 조건: "XCTest 실행" 단계가 QA 절차에 남아 있는 경우
- [ ] evaluator.md QA 모드 테스트 절차에서 XCUITest 실행이 QA 전담임을 명시하고 있다 — FAIL 조건: XCUITest 실행 책임이 QA에 명확히 귀속되어 있지 않은 경우

### [필수] Functionality — 역할 간 규칙 충돌이 없는가

- [ ] generator.md와 evaluator.md 사이에 동일한 테스트를 두 번 실행하도록 요구하는 규칙이 없다 — FAIL 조건: 두 파일을 동시에 따를 때 XCTest 또는 XCUITest가 중복 실행되는 경우
- [ ] generator.md의 산출물 목록에서 XCUITest 항목이 "(작성만, 실행은 QA)" 취지로 표현되어 있다 — FAIL 조건: 산출물에 XCUITest가 실행 포함으로 기술된 경우
- [ ] evaluator.md qa.md 형식의 "빌드 및 단위 테스트" 섹션에서 XCTest 결과를 Generator 자체 점검 결과 참조로 처리하고 있다 — FAIL 조건: QA가 XCTest를 직접 실행·기록하도록 요구하는 경우

### [권장] Visual Design — 문서 가독성과 일관성

- [ ] generator.md plan.md 형식의 자체 점검 결과 표에 XCUITest 행이 없다 — FAIL 조건: XCUITest 행이 Generator 자체 점검 표에 남아 있는 경우
- [ ] checklist.md 형식의 Generator 자체 점검 표에서 XCUITest 항목이 "QA 담당"으로 표시되어 있다 — FAIL 조건: XCUITest 항목이 Generator 결과 기입란으로 남아 있는 경우
- [ ] 수정된 문구가 기존 파일의 문체·형식과 일관되다 — FAIL 조건: 추가된 문구의 어조나 형식이 기존 내용과 현저히 다른 경우

### [권장] Code Quality — 문서 구조 오류가 없는가

- [ ] generator.md 수정 후 마크다운 표·목록 형식이 깨지지 않는다 — FAIL 조건: 표나 목록이 렌더링 불가한 경우
- [ ] evaluator.md 수정 후 마크다운 표·목록 형식이 깨지지 않는다 — FAIL 조건: 표나 목록이 렌더링 불가한 경우

### [선택] 추가 검증

- [ ] planner.md, reporter.md, publisher.md는 변경되지 않았다

## Generator 자체 점검 결과
> Generator가 구현 완료 후 채웁니다.

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | 해당 없음 | 문서 수정 |
| XCTest(단위 테스트) | 해당 없음 | 문서 수정 |
| XCUITest(UI 테스트) | - (QA 담당) | |
| Product Depth 자체 점검 | PASS | 6개 필수 항목 모두 수정 완료 |
| Functionality 자체 점검 | PASS | generator.md와 evaluator.md 간 테스트 중복 없음 확인 |
