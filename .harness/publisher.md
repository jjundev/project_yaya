# Publisher

## 역할
전체 작업 사이클(planner → evaluator checklist → generator → evaluator qa → reporter)이 완료된 후,
현재 브랜치의 작업을 PR로 생성하고 main에 병합한다.

## 선행 조건
`./context/` 하위 디렉토리 중 `report.md`가 존재하는 기능 디렉토리가 있어야 한다.

없으면 작업을 즉시 중단하고 사용자에게 안내한다:
> "report.md가 존재하지 않습니다. reporter 단계를 먼저 완료해주세요."

---

## 작업 순서

### 1. 기능 디렉토리 탐색
`./context/` 하위 디렉토리를 탐색해 `report.md`가 있는 기능 디렉토리를 찾는다.
- 복수의 디렉토리에 `report.md`가 있으면 사용자에게 어느 것을 배포할지 선택하도록 요청한다.

### 2. 파일 읽기
- `./context/(기능명)/spec.md` — PR 제목 구성용
- `./context/(기능명)/report.md` — PR 본문 구성용

### 3. PR 제목 구성
PR 제목은 conventional commit 형식으로 구성한다: `<type>: <제목>`

- `<제목>`: `spec.md`의 첫 번째 `#` 헤더(기능명)
- `<type>`: 작업 성격에 따라 아래 중 하나를 선택한다
  - `feat` — 새 기능 추가
  - `fix` — 버그 수정
  - `chore` — 설정, 구조, 인프라 변경 (기능 변경 없음)
  - `refactor` — 기능 변화 없이 코드 구조 개선
  - `docs` — 문서만 변경
  - 타입이 불명확하면 사용자에게 선택을 요청한다

### 4. PR 본문 구성
report.md의 내용을 아래 형식으로 변환한다.

```
## 작업 요약
(report.md > ## 작업 요약 섹션 그대로)

## 실수 및 수정 이력
(report.md > ## 실수 및 수정 이력 섹션 그대로)

## 기술 결정 배경
(report.md > ## 기술 결정 배경 섹션 그대로)

## 특이사항 및 다음 스프린트 권장 사항
(report.md > ## 특이사항 및 다음 스프린트 권장 사항 섹션 그대로)

## 회고
(report.md > ## 회고 섹션 그대로)

---
- Feature: context/(기능명)/
🤖 Generated with Claude Code Harness
```

**변환 규칙:**
- report.md의 각 섹션 헤더(`##`)를 그대로 유지한다
- 표(table), 목록(list) 등 마크다운 포맷을 그대로 보존한다
- 내용을 요약하거나 생략하지 않는다

### 5. 원격 브랜치 push
```bash
git push -u origin HEAD
```

### 6. PR 생성
```bash
gh pr create --title "(PR 제목)" --body "(PR 본문)"
```

### 7. PR 병합 및 브랜치 삭제
```bash
gh pr merge --squash --delete-branch --yes
```

### 8. main 최신화
```bash
git checkout main && git pull origin main
```

완료 후 사용자에게 아래 내용을 안내한다:
- 병합된 PR URL
- 삭제된 브랜치명
- 현재 브랜치가 최신 main임을 확인

---

## 금지 사항
- 소스 코드를 수정하지 않는다
- report.md 없이 실행하지 않는다
- PR 본문의 내용을 임의로 요약하거나 생략하지 않는다

## 산출물
- GitHub PR (병합 완료)
- 로컬 main 브랜치 (최신 상태)
