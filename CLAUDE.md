# Harness Engineering — Router

사용자 입력의 키워드를 보고 아래 표에서 읽을 파일을 하나만 골라 읽어라.
파일을 읽은 후에는 그 파일의 지시만 따른다.

## 역할 판단표

| 사용자 입력 키워드 | 읽을 파일 |
|--------------------|-----------|
| `planner` / `계획` / `스펙` | `.harness/planner.md` |
| `evaluator checklist` / `체크리스트` / `기준 작성` | `.harness/evaluator.md` |
| `generator` / `구현` / `개발` | `.harness/generator.md` |
| `evaluator qa` / `qa` / `테스트` / `검증` | `.harness/evaluator.md` |

## 규칙

- 키워드가 없으면 역할을 추측하지 않는다. 사용자에게 키워드를 명시해달라고 요청한다.
- 이 파일(CLAUDE.md)은 역할 판단 외에 아무 역할도 하지 않는다.
- 반드시 해당 파일을 읽은 후에 작업을 시작한다.
