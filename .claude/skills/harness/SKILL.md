---
name: harness
description: Yaya 7단계 하네스 파이프라인 자동 실행 (planner → publisher). 각 역할을 독립 컨텍스트로 순차 실행하며 GAN 루프(generator ↔ evaluator)를 자동 반복한다.
user-invocable: true
---

# /harness — 하네스 파이프라인 실행

## 사용법

```
/harness <feature> [options]
```

## 이 스킬이 호출되면

### 1단계: 프로젝트 루트 탐지

워크트리 내부에서 실행될 수 있으므로, 절대경로를 하드코딩하지 않는다.
아래 명령으로 프로젝트 루트를 찾는다:

```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

### 2단계: 환경 검증

```bash
# harness.py 존재 확인
test -f "$PROJECT_ROOT/harness.py"

# venv + claude-agent-sdk 확인
"$PROJECT_ROOT/.venv/bin/python" -c "from claude_agent_sdk import query" 2>/dev/null
```

**없으면 설치 안내:**
```bash
cd "$PROJECT_ROOT"
uv venv .venv --python 3.12
source .venv/bin/activate
uv pip install claude-agent-sdk
```

### 3단계: dry-run으로 경로 확인

반드시 먼저 `--dry-run`을 실행해서 사용자에게 실행 경로를 보여준다:

```bash
"$PROJECT_ROOT/.venv/bin/python" "$PROJECT_ROOT/harness.py" <feature> <options> --dry-run
```

사용자가 확인하면 4단계로 진행한다.

### 4단계: 파이프라인 실행

```bash
"$PROJECT_ROOT/.venv/bin/python" "$PROJECT_ROOT/harness.py" <feature> <options>
```

timeout은 600000ms(10분)으로 설정한다. 파이프라인은 장시간 실행될 수 있으므로 background로 실행하고 완료를 기다린다.

## 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--from <role>` | 시작 역할 | planner |
| `--to <role>` | 종료 역할 | publisher |
| `--auto` | 인간 게이트 없이 완전 자동 | off |
| `--max-rounds N` | GAN 루프 최대 반복 | 3 |
| `--desc "텍스트"` | planner에 전달할 기능 설명 | - |
| `--dry-run` | 경로만 출력 | off |

역할 목록: `planner`, `checklister`, `generator-plan`, `reviewer`, `generator-impl`, `evaluator`, `reporter`, `publisher`

## 예시

```
/harness investment_onboarding
/harness investment_onboarding --auto
/harness investment_onboarding --from generator-impl --auto
/harness investment_onboarding --dry-run
/harness new_feature --desc "사용자 설정 화면 추가" --auto --max-rounds 2
```

## 인자 파싱 규칙

사용자가 자연어로 입력할 수 있다. 아래처럼 매핑한다:

- "investment_onboarding 자동으로" → `investment_onboarding --auto`
- "investment_onboarding generator부터" → `investment_onboarding --from generator-impl`
- "investment_onboarding 경로만 확인" → `investment_onboarding --dry-run`
- "new_feature 설명: 쿠폰 시스템" → `new_feature --desc "쿠폰 시스템"`

## 파이프라인 구조

```
planner → checklister → generator-plan → reviewer → generator-impl ↔ evaluator → reporter → publisher
                              [gate]        [gate]       [GAN 루프]
```

- **인간 게이트**: `generator-plan`, `reviewer` 완료 후 사용자 확인 대기 (`--auto`면 건너뜀)
- **GAN 루프**: generator-impl과 evaluator가 qa.md PASS까지 자동 반복 (최대 `--max-rounds`)
- 각 역할은 독립 Claude Code 세션(컨텍스트 격리)으로 실행된다
- `context/<feature>/` 디렉토리의 파일로 역할 간 데이터를 전달한다
