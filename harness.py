#!/usr/bin/env python3
"""Yaya 하네스 자동화 — claude_agent_sdk 기반 파이프라인 실행기.

Usage:
    python harness.py <feature> [options]

Examples:
    python harness.py investment_onboarding
    python harness.py investment_onboarding --from reviewer --to evaluator
    python harness.py investment_onboarding --auto --max-rounds 3
    python harness.py investment_onboarding --from generator-impl --auto
    python harness.py investment_onboarding --dry-run
"""
from __future__ import annotations

import argparse
import asyncio
import sys
import time
from pathlib import Path

from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, SystemMessage, query

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent

def _find_project_root() -> Path:
    """Find the actual project root via git, handling worktrees."""
    import subprocess
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, cwd=Path.cwd(),
        )
        if result.returncode == 0:
            return Path(result.stdout.strip())
    except FileNotFoundError:
        pass
    return PROJECT_ROOT

ROLE_ORDER = [
    "planner",
    "checklister",
    "generator-plan",
    "reviewer",
    "generator-impl",
    "evaluator",
    "reporter",
    "publisher",
]

MODEL_OPUS = "claude-opus-4-6"
MODEL_SONNET = "claude-sonnet-4-6"

ROLE_MODELS: dict[str, str] = {
    "generator-plan": MODEL_OPUS,
    "generator-impl": MODEL_OPUS,
}

HUMAN_GATES: dict[str, str] = {
    "generator-plan": "plan.md를 검토한 후 계속하시겠습니까?",
    "reviewer": "review.md를 확인했습니까? 구현을 진행하시겠습니까?",
}

ROLE_PROMPTS: dict[str, str] = {
    "planner": "planner 역할로 기능 스펙 작성: {feature}\n{extra}",
    "checklister": "checklister 역할로 {feature} 완료 기준 작성.",
    "generator-plan": (
        "generator 역할. context/{feature}/spec.md, checklist.md 읽고 "
        "plan.md만 작성. 구현 금지."
    ),
    "reviewer": "reviewer 역할로 context/{feature}/plan.md 검토. review.md 작성.",
    "generator-impl": (
        "generator 역할. context/{feature}/plan.md 존재하므로 구현 모드 실행.\n{extra}"
    ),
    "evaluator": "evaluator 역할로 context/{feature} QA 진행. qa.md 작성.\n{extra}",
    "reporter": "reporter 역할로 context/{feature} 최종 보고서 작성.",
    "publisher": "publisher 역할로 PR 생성 후 병합. 워크트리 정리.",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


class HarnessError(Exception):
    """Harness pipeline error."""


def _log(msg: str) -> None:
    print(f"\033[36m[harness]\033[0m {msg}", flush=True)


def _log_error(msg: str) -> None:
    print(f"\033[31m[harness]\033[0m {msg}", file=sys.stderr, flush=True)


def detect_worktree() -> Path:
    """Return the current working tree path (worktree or project root).

    Uses `git rev-parse --show-toplevel` which correctly returns
    the worktree root when inside a worktree, or the main repo root otherwise.
    """
    return _find_project_root()


def build_prompt(role: str, feature: str, extra: str = "") -> str:
    template = ROLE_PROMPTS[role]
    return template.format(feature=feature, extra=extra).strip()


def make_options(worktree_path: Path, role: str) -> ClaudeAgentOptions:
    model = ROLE_MODELS.get(role, MODEL_SONNET)
    return ClaudeAgentOptions(
        model=model,
        cwd=str(worktree_path),
        allowed_tools=["Read", "Write", "Edit", "Bash", "Glob", "Grep"],
        permission_mode="acceptEdits",
        setting_sources=["project"],
    )


def parse_qa_verdict(qa_path: Path) -> str:
    """Parse qa.md for 최종 판정 line → PASS / FAIL / UNKNOWN."""
    if not qa_path.exists():
        return "UNKNOWN"
    for line in qa_path.read_text(encoding="utf-8").splitlines():
        if "최종 판정" in line:
            if "PASS" in line:
                return "PASS"
            if "FAIL" in line:
                return "FAIL"
    return "UNKNOWN"


def human_gate(role: str) -> bool:
    """Prompt human for confirmation. Returns True if approved."""
    prompt_msg = HUMAN_GATES.get(role)
    if not prompt_msg:
        return True
    try:
        resp = input(f"\033[33m[gate]\033[0m [{role}] 완료. {prompt_msg} [y/N] ")
        return resp.strip().lower() == "y"
    except (EOFError, KeyboardInterrupt):
        print()
        return False


# ---------------------------------------------------------------------------
# Core: run a single role
# ---------------------------------------------------------------------------


async def run_role(
    role: str, feature: str, worktree_path: Path, extra: str = ""
) -> str:
    """Run a single harness role via claude_agent_sdk query()."""
    prompt = build_prompt(role, feature, extra)
    _log(f"▶ {role} 시작")
    start = time.monotonic()

    result_text = ""
    session_id = None

    async for msg in query(prompt=prompt, options=make_options(worktree_path, role)):
        if isinstance(msg, SystemMessage) and msg.subtype == "init":
            session_id = getattr(msg, "session_id", None)
        elif isinstance(msg, ResultMessage):
            result_text = msg.result or ""
            elapsed = time.monotonic() - start
            if msg.is_error:
                _log_error(
                    f"✗ {role} 실패 ({elapsed:.0f}s) — {msg.subtype}"
                )
                if msg.errors:
                    for e in msg.errors:
                        _log_error(f"  {e}")
                raise HarnessError(f"{role} failed: {msg.subtype}")
            _log(
                f"✓ {role} 완료 ({elapsed:.0f}s, "
                f"turns={msg.num_turns}, "
                f"cost=${msg.total_cost_usd or 0:.4f})"
            )

    return result_text


# ---------------------------------------------------------------------------
# GAN loop: generator-impl ↔ evaluator
# ---------------------------------------------------------------------------


async def run_gan_loop(
    feature: str,
    worktree_path: Path,
    max_rounds: int = 3,
    auto: bool = False,
) -> bool:
    """Run Generator ↔ Evaluator loop. Returns True on PASS."""
    context_dir = worktree_path / "context" / feature
    qa_path = context_dir / "qa.md"

    for round_num in range(1, max_rounds + 1):
        _log(f"── GAN 라운드 {round_num}/{max_rounds} ──")

        # Generator (impl or rework)
        extra = ""
        if round_num > 1:
            extra = f"재작업 모드. qa.md FAIL 항목 수정. {round_num}번째 시도."
        await run_role("generator-impl", feature, worktree_path, extra)

        # Evaluator
        await run_role("evaluator", feature, worktree_path)

        # Parse verdict
        verdict = parse_qa_verdict(qa_path)
        _log(f"판정: {verdict}")

        if verdict == "PASS":
            _log("GAN 루프 PASS")
            return True

        if round_num == max_rounds:
            _log_error(f"GAN 루프 {max_rounds}라운드 후 FAIL")
            return False

        # Archive qa.md before next round
        archive = context_dir / f"qa_round{round_num}.md"
        qa_path.rename(archive)
        _log(f"qa.md → {archive.name}")

        if not auto:
            if not human_gate("evaluator"):
                return False

    return False


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------


async def run_pipeline(
    feature: str,
    worktree_path: Path,
    from_role: str,
    to_role: str,
    auto: bool,
    max_rounds: int,
    desc: str | None,
    dry_run: bool,
) -> None:
    """Run the harness pipeline from `from_role` to `to_role`."""

    # Validate roles
    if from_role not in ROLE_ORDER:
        raise HarnessError(f"Unknown role: {from_role}")
    if to_role not in ROLE_ORDER:
        raise HarnessError(f"Unknown role: {to_role}")

    start_idx = ROLE_ORDER.index(from_role)
    end_idx = ROLE_ORDER.index(to_role)
    if start_idx > end_idx:
        raise HarnessError(f"--from ({from_role}) must come before --to ({to_role})")

    roles = ROLE_ORDER[start_idx : end_idx + 1]

    if dry_run:
        print("실행 경로:", " → ".join(roles))
        if auto:
            print("모드: 완전 자동")
        else:
            gates_in_range = [r for r in roles if r in HUMAN_GATES]
            if gates_in_range:
                print(f"인간 게이트: {', '.join(gates_in_range)}")
        return

    # Ensure context directory
    context_dir = worktree_path / "context" / feature
    context_dir.mkdir(parents=True, exist_ok=True)

    _log(f"파이프라인 시작: {feature}")
    _log(f"경로: {' → '.join(roles)}")
    _log(f"워크트리: {worktree_path}")
    pipeline_start = time.monotonic()

    i = 0
    while i < len(roles):
        role = roles[i]

        # GAN loop section
        if role == "generator-impl" and "evaluator" in roles[i:]:
            success = await run_gan_loop(
                feature, worktree_path, max_rounds, auto
            )
            if not success:
                _log_error("GAN 루프 실패. 파이프라인 중단.")
                sys.exit(1)
            # Skip past evaluator
            eval_idx = roles.index("evaluator", i)
            i = eval_idx + 1
            continue

        # Build extra context for planner --desc
        extra = ""
        if role == "planner" and desc:
            extra = f"기능 설명: {desc}"

        await run_role(role, feature, worktree_path, extra)

        # Human gate
        if role in HUMAN_GATES and not auto:
            if not human_gate(role):
                _log("사용자에 의해 중단됨.")
                return

        i += 1

    elapsed = time.monotonic() - pipeline_start
    _log(f"파이프라인 완료 ({elapsed:.0f}s)")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Yaya 하네스 자동화 파이프라인",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("feature", help="기능 이름 (context 디렉토리명)")
    parser.add_argument(
        "--from",
        dest="from_role",
        default=ROLE_ORDER[0],
        choices=ROLE_ORDER,
        help=f"시작 역할 (default: {ROLE_ORDER[0]})",
    )
    parser.add_argument(
        "--to",
        dest="to_role",
        default=ROLE_ORDER[-1],
        choices=ROLE_ORDER,
        help=f"종료 역할 (default: {ROLE_ORDER[-1]})",
    )
    parser.add_argument(
        "--auto",
        action="store_true",
        help="인간 게이트 없이 완전 자동 실행",
    )
    parser.add_argument(
        "--max-rounds",
        type=int,
        default=3,
        help="GAN 루프 최대 반복 (default: 3)",
    )
    parser.add_argument(
        "--desc",
        help="planner에게 전달할 기능 설명",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="실행 경로만 출력 (실제 실행 안 함)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    worktree_path = detect_worktree()

    try:
        asyncio.run(
            run_pipeline(
                feature=args.feature,
                worktree_path=worktree_path,
                from_role=args.from_role,
                to_role=args.to_role,
                auto=args.auto,
                max_rounds=args.max_rounds,
                desc=args.desc,
                dry_run=args.dry_run,
            )
        )
    except HarnessError as e:
        _log_error(str(e))
        sys.exit(1)
    except KeyboardInterrupt:
        print()
        _log("중단됨.")
        sys.exit(130)


if __name__ == "__main__":
    main()
