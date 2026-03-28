# 하네스 테스트 역할 분리 구현 계획

## 구현 범위

spec.md 기준으로 이번에 구현할 항목:
- `.harness/generator.md`: XCUITest 실행 책임 제거, 코드 작성은 유지, 금지 사항 갱신
- `.harness/evaluator.md`: XCTest 재실행 단계 제거, XCUITest를 QA 전담으로 명확화
- 두 파일 내 plan.md / checklist.md 형식 업데이트

포함하지 않는 항목:
- planner.md, reporter.md, publisher.md: 변경 범위 외

## 기술 결정

| 항목 | 결정 | 이유 |
|------|------|------|
| XCUITest 코드 작성 주체 | Generator 유지 | 구현 맥락을 아는 Generator가 테스트 코드도 작성하는 것이 적합 |
| XCUITest 실행 주체 | QA로 이전 | 독립적 검증을 위해 실행은 QA가 담당 |
| XCTest 실행 주체 | Generator 유지 | 로직 검증은 구현 직후 즉시 확인이 효과적 |
| QA의 XCTest 처리 | Generator 자체 점검 결과 참조 | 재실행 중복 제거 |

## 파일 변경 목록

### 신규 생성
없음

### 수정
- `.harness/generator.md` — 구현 순서, 금지 사항, 산출물, plan.md 형식, checklist.md 형식 변경
- `.harness/evaluator.md` — QA 모드 테스트 절차, qa.md 형식 변경

### 테스트
- 해당 없음 (문서 파일 수정)

## 구현 순서

1. `.harness/generator.md` 수정
   - 구현 순서 3번: "XCUITest 작성 + 실행" → "XCUITest 코드 작성 (실행은 QA 담당)"
   - 금지 사항: "UI 인터랙션 검증이 필요한 기능임에도 XCUITest 없이 작업을 종료하지 않는다" → "작성한 XCUITest를 직접 실행하지 않는다 (실행은 QA 담당)"
   - 산출물: XCUITest 항목에 "(작성만, 실행은 QA)" 명시
   - plan.md 형식 자체 점검 결과: XCUITest 행 제거
   - checklist.md Generator 자체 점검 표: XCUITest 행을 "- (QA 담당)"으로 고정

2. `.harness/evaluator.md` 수정
   - QA 모드 테스트 절차 2번(XCTest 실행) 제거
   - XCUITest 실행 단계에 "Generator가 작성한 XCUITest 코드를 실행한다" 명시
   - qa.md 형식의 "빌드 및 단위 테스트" 섹션: XCTest 결과를 "Generator 자체 점검 결과 참조"로 변경

## 자체 점검 결과
> 구현 완료 후 기입

- 빌드: 해당 없음 (문서 수정)
- XCTest(단위 테스트): 해당 없음
- Product Depth 자체 점검: -
- Functionality 자체 점검: -

## 특이사항
- QA에서 evaluator.md checklist.md 형식 템플릿(line 71)의 XCUITest 행이 미수정된 것을 발견. 재작업에서 `| - | |` → `| - (QA 담당) | |` 로 수정.
