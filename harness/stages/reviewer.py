"""Reviewer 스테이지 — Plan 또는 Implementation을 검토하고 PASS/FAIL을 반환한다."""
import subprocess

from harness.agent import run_agent
import harness.config as cfg
from harness.config import PipelineError
from harness.review import (
    get_latest_failed_review_content,
    is_review_pass,
    next_review_version,
    sync_review_aliases,
)

_WRITE_RESTRICTION = "NOTE: write_file은 반드시 jobs/ 경로에만 사용하세요. 소스 코드 수정은 절대 금지입니다."


def _git_status_snapshot() -> dict[str, str]:
    """git status --porcelain 스냅샷(path -> status code)"""
    r = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=cfg.PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        return {}

    snapshot: dict[str, str] = {}
    for raw_line in r.stdout.splitlines():
        if len(raw_line) < 4:
            continue
        status = raw_line[:2]
        path_part = raw_line[3:].strip()
        # rename/copy 포맷: "old -> new"
        if " -> " in path_part:
            path_part = path_part.split(" -> ", 1)[1].strip()
        if path_part:
            snapshot[path_part] = status
    return snapshot


def _validate_reviewer_write_scope(feature: str, before: dict[str, str], after: dict[str, str]) -> None:
    allowed_prefix = f"jobs/{feature}/"
    violations: list[str] = []
    for path in sorted(set(before) | set(after)):
        if before.get(path) == after.get(path):
            continue
        if path.startswith(allowed_prefix):
            continue
        violations.append(path)

    if violations:
        joined = "\n".join(f"  - {p}" for p in violations[:20])
        raise PipelineError(
            "\n[ERROR] Reviewer가 jobs/ 범위를 벗어난 변경을 만들었습니다.\n"
            f"{joined}\n"
            "  reviewer 단계는 jobs/<feature>/ 산출물만 수정해야 합니다."
        )


def stage_reviewer_plan(feature: str) -> tuple[bool, str]:
    """Plan Review를 실행하고 (passed, feedback_content) 를 반환한다."""
    jobs = cfg.JOBS_DIR / feature
    version = next_review_version(jobs, "plan")
    fail_output = jobs / f"review-plan_{version:02d}.md"
    pass_output = jobs / f"review-checklist_{version:02d}.md"
    user_message = (
        f"Feature: {feature}\n"
        f"Review mode: PLAN\n"
        f"Target: {jobs / 'implement-plan.md'}\n"
        f"Output on FAIL: {fail_output}\n"
        f"Output on PASS: {pass_output}\n"
        f"{_WRITE_RESTRICTION}"
    )
    before = _git_status_snapshot()
    run_agent("reviewer", user_message)
    sync_review_aliases(jobs, "plan")
    after = _git_status_snapshot()
    _validate_reviewer_write_scope(feature, before, after)

    jobs_dir = cfg.JOBS_DIR / feature
    passed = is_review_pass(jobs_dir, "plan")
    feedback = get_latest_failed_review_content(jobs_dir, "plan")
    return passed, feedback


def stage_reviewer_impl(feature: str) -> tuple[bool, str]:
    """Implementation Review를 실행하고 (passed, feedback_content) 를 반환한다."""
    jobs = cfg.JOBS_DIR / feature
    version = next_review_version(jobs, "impl")
    output = jobs / f"review-implement_{version:02d}.md"
    user_message = (
        f"Feature: {feature}\n"
        f"Review mode: IMPLEMENTATION\n"
        f"Jobs dir: {jobs}\n"
        f"Output: {output}\n"
        f"{_WRITE_RESTRICTION}"
    )
    before = _git_status_snapshot()
    run_agent("reviewer", user_message)
    sync_review_aliases(jobs, "impl")
    after = _git_status_snapshot()
    _validate_reviewer_write_scope(feature, before, after)

    jobs_dir = cfg.JOBS_DIR / feature
    passed = is_review_pass(jobs_dir, "impl")
    feedback = get_latest_failed_review_content(jobs_dir, "impl")
    return passed, feedback
