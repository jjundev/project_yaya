import os
from pathlib import Path


class PipelineError(Exception):
    """파이프라인 실행 중 복구 불가능한 오류."""


PROJECT_ROOT = Path(__file__).parent.parent
SKILLS_DIR = PROJECT_ROOT / ".claude" / "skills"
JOBS_DIR = PROJECT_ROOT / "jobs"

MAX_REVIEW_LOOPS = int(os.environ.get("HARNESS_MAX_GAN", "3"))

REMOTE = os.environ.get("HARNESS_REMOTE", "origin")
BASE_BRANCH = os.environ.get("HARNESS_BASE_BRANCH", "main")

MODELS: dict[str, str] = {
    "planner":     "claude-opus-4-6",
    "implementor": "claude-opus-4-6",
    "reviewer":    "claude-sonnet-4-6",
    "reporter":    "claude-sonnet-4-6",
    "publisher":   "claude-haiku-4-5-20251001",
    "spector":     "claude-opus-4-6",
}

# Claude Code 내장 도구명 — 에이전트별 허용 목록
AGENT_TOOLS: dict[str, list[str]] = {
    "planner":     ["Read", "Glob", "Grep", "Write", "Bash"],
    "reviewer":    ["Read", "Glob", "Grep", "Bash", "Write"],   # jobs/ 경로만 허용 (system prompt 제약)
    "implementor": ["Read", "Write", "Edit", "Bash", "Glob", "Grep"],
    "reporter":    ["Read", "Write", "Bash", "Glob", "Grep"],
    "publisher":   ["Read", "Write", "Bash", "Glob", "Grep"],
    "spector":     ["Read", "Glob", "Grep", "Write"],
}


def set_worktree_root(worktree: Path) -> None:
    """워크트리 경로를 기준으로 전역 경로 상수를 재설정한다."""
    global PROJECT_ROOT, SKILLS_DIR, JOBS_DIR
    PROJECT_ROOT = worktree
    SKILLS_DIR = worktree / ".claude" / "skills"
    JOBS_DIR = worktree / "jobs"
