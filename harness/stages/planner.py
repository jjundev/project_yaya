"""Planner 스테이지 — 구현 계획(implement-plan.md)을 생성한다."""
from __future__ import annotations

from harness.agent import run_agent
import harness.config as cfg


def stage_planner(feature: str, review_feedback: str | None = None) -> None:
    """Planner 에이전트를 실행한다.

    review_feedback가 있으면 이전 plan review 실패 내용을 함께 전달해
    계획을 수정하도록 유도한다.
    """
    feedback_section = ""
    if review_feedback:
        feedback_section = (
            "\n\n---\n"
            "이전 Plan Review 결과가 FAIL입니다. 아래 피드백을 반영하여 계획을 수정하세요:\n\n"
            f"{review_feedback}"
        )

    jobs = cfg.JOBS_DIR / feature
    req = cfg.PROJECT_ROOT / "requirements" / f"requirement_{feature}.md"

    user_message = (
        f"Feature: {feature}\n"
        f"Jobs dir: {jobs}\n"
        f"Requirement: {req}\n"
        f"Output: {jobs / 'implement-plan.md'}"
        f"{feedback_section}"
    )

    run_agent("planner", user_message)
