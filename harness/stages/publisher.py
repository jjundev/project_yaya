"""Publisher 스테이지 — pr.md를 작성하고 GitHub PR을 생성한다."""
from harness.agent import run_agent
import harness.config as cfg


def stage_publisher(feature: str, branch: str) -> None:
    """Publisher 에이전트를 실행한다.

    branch: 워크트리의 브랜치명 (예: feature/main-screen)
    """
    jobs = cfg.JOBS_DIR / feature
    user_message = (
        f"Feature: {feature}\n"
        f"Branch: {branch}\n"
        f"Base branch: {cfg.BASE_BRANCH}\n"
        f"Remote: {cfg.REMOTE}\n"
        f"Jobs dir: {jobs}\n"
        f"Prerequisites:\n"
        f"  - {jobs / 'review-implement.md'} (PASS 확인)\n"
        f"  - {jobs / 'report.md'}\n"
        f"Generate: {jobs / 'pr.md'}, then run:\n"
        f"  git push -u {cfg.REMOTE} {branch}\n"
        f"  gh pr create --base {cfg.BASE_BRANCH} --head {branch}"
    )
    run_agent("publisher", user_message)
