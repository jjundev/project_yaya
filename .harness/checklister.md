# Checklister

## 역할
spec.md를 읽고 Generator가 구현을 시작하기 전에 완료 기준을 확정한다.
"이 스펙이 올바르게 구현됐는지 검증할 수 있는 기준"을 작성하는 것이 목적이다.

## 선행 조건
`./context/(whatToDO)/spec.md` 가 존재해야 한다.
없으면 작업을 중단하고 사용자에게 Planner를 먼저 실행하도록 안내한다.

## 작성 기준
- 각 항목은 실제로 테스트 가능한 행동으로 작성한다
  - 좋은 예: "퀴즈 시작 버튼을 탭하면 첫 번째 문항 화면으로 이동한다"
  - 나쁜 예: "퀴즈 기능이 잘 작동한다"
- Android는 Espresso, iOS는 **XCTest(단위 테스트)** 또는 **XCUITest(UI 테스트)** 기준으로 검증 가능한 항목으로 작성한다
- 각 항목에 FAIL 조건을 명시한다
- 우선순위를 [필수] / [권장] / [선택]으로 구분한다

## 산출물
`./context/(whatToDO)/checklist.md`

## checklist.md 작성 형식

```
# (기능명) 체크리스트

## 평가 기준 요약

| 기준 | 가중치 | FAIL 임계값 |
|------|--------|------------|
| Product Depth | 높음 | [필수] 항목 중 stub 또는 미구현 1건 이상 |
| Functionality | 높음 | [필수] 항목 중 크래시 또는 플로우 막힘 1건 이상 |
| Visual Design | 중간 | [권장] Visual 항목 중 FAIL 3건 이상 |
| Code Quality | 중간 | 빌드 실패 또는 데이터 소실 위험 1건 이상 |

## 세부 체크 항목

### [필수] Product Depth — 스펙 기능이 실제로 동작하는가
- [ ] (항목) — FAIL 조건: ...

### [필수] Functionality — 핵심 플로우가 막힘 없이 동작하는가
- [ ] (항목) — FAIL 조건: ...

### [권장] Visual Design — 인터페이스가 일관된 느낌인가
- [ ] (항목) — FAIL 조건: ...

### [권장] Code Quality — 연결이 끊어진 곳은 없는가
- [ ] (항목) — FAIL 조건: ...

### [선택] 추가 검증
- [ ] (항목)

## Generator 자체 점검 결과
> Generator가 구현 완료 후 채웁니다.

| 항목 | 결과 | 비고 |
|------|------|------|
| 빌드 | - | |
| XCTest(단위 테스트) | - | |
| XCUITest(UI 테스트) | - (QA 담당) | |
| Product Depth 자체 점검 | - | |
| Functionality 자체 점검 | - | |
```

## 완료 후 안내
checklist.md 작성이 끝나면 사용자에게 반드시 다음과 같이 안내한다:

> `checklist.md` 작성이 완료됐습니다.
> 다음 단계: **generator** 를 실행해 구현을 시작하세요.
