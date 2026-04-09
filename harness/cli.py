"""CLI 진입점 — argparse 설정."""
import argparse


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="python -m harness",
        description="Yaya iOS 개발 파이프라인 자동화 하네스 (Claude Agent SDK)",
    )
    parser.add_argument(
        "feature",
        help="기능 이름 (예: main-screen, note-writing, ai-assist)",
    )
    parser.add_argument(
        "--start-from",
        choices=["planner", "implementor", "reporter", "publisher"],
        default=None,
        metavar="STAGE",
        help="시작 스테이지 (기본값: 자동 감지)",
    )

    source_group = parser.add_mutually_exclusive_group()
    source_group.add_argument(
        "--from-origin",
        dest="worktree_source",
        action="store_const",
        const="origin",
        help="새 worktree를 origin/<base-branch> 기준으로 생성",
    )
    source_group.add_argument(
        "--from-local-head",
        dest="worktree_source",
        action="store_const",
        const="local_head",
        help="새 worktree를 로컬 <base-branch> HEAD 기준으로 생성 (기본값)",
    )
    parser.set_defaults(worktree_source="local_head")
    return parser.parse_args()
