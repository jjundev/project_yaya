# Publisher

## 역할
전체 작업 사이클(planner → checklister → generator → reviewer → generator → evaluator → reporter → publisher)이 완료된 후,
현재 브랜치의 작업을 PR로 생성하고 main에 병합한다.

## 선행 조건
`./context/` 하위 디렉토리 중 `report.md`가 존재하는 기능 디렉토리가 있어야 한다.

없으면 작업을 즉시 중단하고 사용자에게 안내한다:
> "report.md가 존재하지 않습니다. reporter 단계를 먼저 완료해주세요."

---

## 작업 순서

### 1. 변경사항 커밋

현재 브랜치에 커밋되지 않은 변경사항이 있는지 확인한다.

```bash
git status
```

- **스테이징되지 않은 파일이 있으면**: `git add -A` 후 커밋
- **커밋 메시지**: 작업 내용을 간략히 요약 (conventional commit 형식 불필요)
- **변경사항이 없으면**: 이 단계를 건너뛴다

```bash
git add -A
git commit -m "(작업 요약)"
```

### 2. 기능 디렉토리 탐색
`./context/` 하위 디렉토리를 탐색해 `report.md`가 있는 기능 디렉토리를 찾는다.
- 복수의 디렉토리에 `report.md`가 있으면 사용자에게 어느 것을 배포할지 선택하도록 요청한다.

### 3. 파일 읽기
- `./context/(기능명)/spec.md` — PR 제목 구성용
- `./context/(기능명)/report.md` — PR 본문 구성용

### 4. PR 제목 구성
PR 제목은 conventional commit 형식으로 구성한다: `<type>: <제목>`

- `<제목>`: `spec.md`의 첫 번째 `#` 헤더(기능명)
- `<type>`: 작업 성격에 따라 아래 중 하나를 선택한다
  - `feat` — 새 기능 추가
  - `fix` — 버그 수정
  - `chore` — 설정, 구조, 인프라 변경 (기능 변경 없음)
  - `refactor` — 기능 변화 없이 코드 구조 개선
  - `docs` — 문서만 변경
  - 타입이 불명확하면 사용자에게 선택을 요청한다

### 5. PR 본문 구성
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

### 6. 원격 브랜치 push
```bash
git push -u origin HEAD
```

### 7. PR 생성
```bash
gh pr create --title "(PR 제목)" --body "(PR 본문)"
```

### 8. PR 병합
```bash
gh pr merge --squash
```

> **워크트리 환경 주의**: `--delete-branch` 플래그는 로컬 브랜치 삭제를 시도하는데,
> `main`이 다른 워크트리에서 이미 체크아웃된 경우 `fatal: 'main' is already used by worktree` 오류가 발생한다.
> 따라서 로컬/원격 브랜치 삭제는 아래 Step 9~10에서 별도로 수행한다.

### 9. 원격 브랜치 삭제
현재 브랜치명을 확인한 후 원격 브랜치를 삭제한다.
```bash
git push origin --delete (현재 브랜치명)
```

삭제 확인:
```bash
git ls-remote --heads origin (현재 브랜치명)
```
출력이 없으면 삭제 완료.

### 10. main 최신화 및 로컬 브랜치 삭제

#### 10-1. main 최신화 (먼저 실행)

워크트리 환경에서는 `git checkout main`이 실패할 수 있으므로, `-C` 플래그로 main 워크트리 경로를 직접 지정해 pull한다.

```bash
git -C /Users/hyunjun/Documents/projects/project_yaya pull origin main
```

#### 10-2. 워크트리·브랜치 정리 (단일 복합 명령으로 실행)

워크트리 환경에서는 현재 체크아웃된 브랜치를 직접 삭제할 수 없으므로, 워크트리를 먼저 제거한 뒤 브랜치를 삭제한다.

아래 명령을 **하나의 Bash 호출**로 실행한다. 분리하면 `git worktree remove` 이후 cwd가 삭제되어 이후 명령이 실패한다.

```bash
BRANCH=$(git branch --show-current) && \
WORKTREE=$(git rev-parse --show-toplevel) && \
REPO=/Users/hyunjun/Documents/projects/project_yaya && \
cd "$REPO" && \
git worktree remove "$WORKTREE" --force && \
git branch -d "$BRANCH"
```

> **주의**: 이미 main에 병합된 브랜치이므로 `-d`(안전 삭제)를 사용한다.
> 워크트리를 제거하지 않고 브랜치 삭제를 시도하면 `cannot delete branch '...' used by worktree` 오류가 발생한다.
> `--force`는 인덱스 상태에 무관하게 워크트리를 제거하기 위한 안전망이다.

완료 후 사용자에게 아래 내용을 안내한다:
- 병합된 PR URL
- 삭제된 원격 브랜치명
- 삭제된 로컬 브랜치명
- 현재 main 브랜치가 최신 상태임을 확인

---

## 금지 사항
- 소스 코드를 수정하지 않는다
- report.md 없이 실행하지 않는다
- PR 본문의 내용을 임의로 요약하거나 생략하지 않는다

## 산출물
- GitHub PR (병합 완료)
- 원격 브랜치 삭제 완료
- 로컬 브랜치 삭제 완료
- 로컬 main 브랜치 (최신 상태)
