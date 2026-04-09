"""Implementor 스테이지 — implement-plan.md에 따라 코드를 구현한다."""
from __future__ import annotations

from harness.agent import run_agent
import harness.config as cfg


def stage_implementor(feature: str, review_feedback: str | None = None) -> None:
    """Implementor 에이전트를 실행한다.

    review_feedback가 있으면 Fix Mode로 동작하도록 지시한다.
    수정 우선순위: CRITICAL → MAJOR → MINOR
    """
    feedback_section = ""
    if review_feedback:
        feedback_section = (
            "\n\n---\n"
            "Implementation Review 결과가 FAIL입니다. "
            "아래 피드백을 CRITICAL → MAJOR → MINOR 순서로 수정하세요:\n\n"
            f"{review_feedback}"
        )

    jobs = cfg.JOBS_DIR / feature

    user_message = (
        f"Feature: {feature}\n"
        f"Jobs dir: {jobs}\n"
        f"Plan: {jobs / 'implement-plan.md'}"
        f"{feedback_section}"
    )

    run_agent("implementor", user_message)
