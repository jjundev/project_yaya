"""Reporter 스테이지 — report.md와 lessons-learned.md를 생성한다."""
from harness.agent import run_agent
import harness.config as cfg


def stage_reporter(feature: str) -> None:
    jobs = cfg.JOBS_DIR / feature
    user_message = (
        f"Feature: {feature}\n"
        f"Base branch: {cfg.BASE_BRANCH}\n"
        f"Remote: {cfg.REMOTE}\n"
        f"Jobs dir: {jobs}\n"
        f"Generate: {jobs / 'report.md'} 와 {jobs / 'lessons-learned.md'}"
    )
    run_agent("reporter", user_message)
