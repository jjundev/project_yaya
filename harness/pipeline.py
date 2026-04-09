"""파이프라인 오케스트레이터.

Planner → (Plan Review Loop) → Implementor → (Impl Review Loop) → Reporter → Publisher
순서로 에이전트를 실행하며, 리뷰 루프는 최대 MAX_REVIEW_LOOPS회 반복한다.
파이프라인 시작 시 기준 브랜치 기반 worktree를 생성하여 격리된 환경에서 작업한다.
"""
from __future__ import annotations

import os
import shutil
from pathlib import Path

import harness.config as cfg
from harness.config import PipelineError
from harness.manifest import PipelineManifestRecorder
from harness.review import (
    check_hard_quality_gate,
    get_latest_failed_review_content,
    is_review_gate_pass,
)
from harness.ui_test_gate import validate_impl_ui_test_gate, validate_plan_ui_test_gate
from harness.stages.implementor import stage_implementor
from harness.stages.planner import stage_planner
from harness.stages.publisher import stage_publisher
from harness.stages.reporter import stage_reporter
from harness.stages.reviewer import stage_reviewer_impl, stage_reviewer_plan
from harness.worktree import branch_name, create_worktree, ensure_worktree, worktree_path

# start_from 순서 인덱스
_STAGE_ORDER = ["planner", "implementor", "reporter", "publisher"]


def _source_project_root() -> Path:
    """현재 실행 중인 harness 소스 트리의 루트를 반환한다."""
    return Path(__file__).resolve().parent.parent


def _ensure_requirement_file(feature: str) -> Path:
    """워크트리 requirement가 없으면 실행 소스 루트에서 보강한다."""
    req_rel = Path("requirements") / f"requirement_{feature}.md"
    target_req = cfg.PROJECT_ROOT / req_rel
    if target_req.exists():
        return target_req

    source_req = _source_project_root() / req_rel
    if source_req.exists() and source_req.resolve() != target_req.resolve():
        target_req.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_req, target_req)
        print(f"  Synced requirement file into worktree: {target_req}", flush=True)
        return target_req

    raise PipelineError(f"\n[ERROR] 요구사항 파일이 없습니다: {target_req}")


def _log(label: str, agent: str) -> None:
    model = cfg.MODELS.get(agent, "")
    print(f"\n{'='*60}", flush=True)
    print(f"  {label}  [{model}]", flush=True)
    print(f"{'='*60}", flush=True)


def _escalate_and_exit(feature: str, stage: str) -> None:
    raise PipelineError(
        f"\n[ERROR] {stage} 리뷰 루프가 {cfg.MAX_REVIEW_LOOPS}회를 초과했습니다.\n"
        f"  수동 검토가 필요합니다: jobs/{feature}/"
    )


def _merge_feedback(*sections: str | None) -> str | None:
    normalized = [s.strip() for s in sections if s and s.strip()]
    if not normalized:
        return None
    return "\n\n---\n\n".join(normalized)


def _require_review_gate_for_start(jobs_dir: Path, review_type: str, stage: str) -> None:
    gate_passed, _, quality = check_hard_quality_gate(jobs_dir, review_type)
    if gate_passed:
        return
    raise PipelineError(
        f"\n[ERROR] {stage} 시작 조건을 만족하지 못했습니다.\n"
        f"  - latest review: {quality.review_file}\n"
        f"  - result: {quality.result}\n"
        f"  - critical: {quality.critical_count}\n"
        f"  - major: {quality.major_count}\n"
        f"  - blocking major: {quality.blocking_major_count}\n"
        f"  unresolved critical/major 이슈를 모두 해소한 뒤 다시 시도하세요."
    )


def _run_plan_review_loop(
    feature: str,
    manifest: PipelineManifestRecorder | None = None,
) -> None:
    jobs_dir = cfg.JOBS_DIR / feature
    feedback = get_latest_failed_review_content(jobs_dir, "plan") or None
    for attempt in range(1, cfg.MAX_REVIEW_LOOPS + 1):
        if manifest:
            manifest.note_stage_attempt(
                "plan_review",
                attempt,
                "planner_started",
                has_feedback=bool(feedback),
            )
        _log(f"[PLANNER] attempt {attempt}/{cfg.MAX_REVIEW_LOOPS}", "planner")
        stage_planner(feature, feedback)

        if manifest:
            manifest.note_stage_attempt("plan_review", attempt, "reviewer_started")
        _log(f"[REVIEWER PLAN] attempt {attempt}/{cfg.MAX_REVIEW_LOOPS}", "reviewer")
        review_passed, review_feedback = stage_reviewer_plan(feature)
        review_feedback = review_feedback or None

        hard_gate_passed, hard_gate_feedback, quality = check_hard_quality_gate(jobs_dir, "plan")
        if manifest:
            manifest.note_quality_gate(
                "plan",
                passed=hard_gate_passed,
                feedback=hard_gate_feedback,
                quality=quality,
            )

        if review_passed and hard_gate_passed:
            gate_passed, gate_feedback = validate_plan_ui_test_gate(
                project_root=cfg.PROJECT_ROOT,
                jobs_dir=cfg.JOBS_DIR / feature,
            )
            if manifest:
                manifest.note_ui_test_gate("plan", passed=gate_passed, feedback=gate_feedback)
            if not gate_passed:
                feedback = _merge_feedback(review_feedback, gate_feedback)
                print(
                    f"  → FAIL (attempt {attempt}/{cfg.MAX_REVIEW_LOOPS}) [UI Test Soft Gate]",
                    flush=True,
                )
                if manifest:
                    manifest.note_stage_attempt(
                        "plan_review",
                        attempt,
                        "failed",
                        reason="ui_test_soft_gate",
                    )
                continue
            print("  → PASS", flush=True)
            if manifest:
                manifest.note_stage_status(
                    "plan_review",
                    "passed",
                    attempts=attempt,
                )
            return

        feedback = _merge_feedback(review_feedback, hard_gate_feedback)
        print(f"  → FAIL (attempt {attempt}/{cfg.MAX_REVIEW_LOOPS})", flush=True)
        if manifest:
            manifest.note_stage_attempt(
                "plan_review",
                attempt,
                "failed",
                reason="review_or_hard_gate",
                review_passed=review_passed,
                hard_gate_passed=hard_gate_passed,
            )
    else:
        if manifest:
            manifest.note_stage_status("plan_review", "failed", reason="max_loop_exceeded")
        _escalate_and_exit(feature, "Plan Review")


def _run_impl_review_loop(
    feature: str,
    manifest: PipelineManifestRecorder | None = None,
) -> None:
    jobs_dir = cfg.JOBS_DIR / feature
    feedback = get_latest_failed_review_content(jobs_dir, "impl") or None
    for attempt in range(1, cfg.MAX_REVIEW_LOOPS + 1):
        if manifest:
            manifest.note_stage_attempt(
                "implementation_review",
                attempt,
                "implementor_started",
                has_feedback=bool(feedback),
            )
        _log(f"[IMPLEMENTOR] attempt {attempt}/{cfg.MAX_REVIEW_LOOPS}", "implementor")
        stage_implementor(feature, feedback)

        if manifest:
            manifest.note_stage_attempt("implementation_review", attempt, "reviewer_started")
        _log(f"[REVIEWER IMPL] attempt {attempt}/{cfg.MAX_REVIEW_LOOPS}", "reviewer")
        review_passed, review_feedback = stage_reviewer_impl(feature)
        review_feedback = review_feedback or None

        hard_gate_passed, hard_gate_feedback, quality = check_hard_quality_gate(jobs_dir, "impl")
        if manifest:
            manifest.note_quality_gate(
                "impl",
                passed=hard_gate_passed,
                feedback=hard_gate_feedback,
                quality=quality,
            )

        if review_passed and hard_gate_passed:
            gate_passed, gate_feedback = validate_impl_ui_test_gate(
                project_root=cfg.PROJECT_ROOT,
                jobs_dir=cfg.JOBS_DIR / feature,
            )
            if manifest:
                manifest.note_ui_test_gate("impl", passed=gate_passed, feedback=gate_feedback)
            if not gate_passed:
                feedback = _merge_feedback(review_feedback, gate_feedback)
                print(
                    f"  → FAIL (attempt {attempt}/{cfg.MAX_REVIEW_LOOPS}) [UI Test Soft Gate]",
                    flush=True,
                )
                if manifest:
                    manifest.note_stage_attempt(
                        "implementation_review",
                        attempt,
                        "failed",
                        reason="ui_test_soft_gate",
                    )
                continue
            print("  → PASS", flush=True)
            if manifest:
                manifest.note_stage_status(
                    "implementation_review",
                    "passed",
                    attempts=attempt,
                )
            return

        feedback = _merge_feedback(review_feedback, hard_gate_feedback)
        print(f"  → FAIL (attempt {attempt}/{cfg.MAX_REVIEW_LOOPS})", flush=True)
        if manifest:
            manifest.note_stage_attempt(
                "implementation_review",
                attempt,
                "failed",
                reason="review_or_hard_gate",
                review_passed=review_passed,
                hard_gate_passed=hard_gate_passed,
            )
    else:
        if manifest:
            manifest.note_stage_status("implementation_review", "failed", reason="max_loop_exceeded")
        _escalate_and_exit(feature, "Implementation Review")


def _auto_detect_start_from(feature: str) -> str:
    """워크트리와 jobs 파일을 기반으로 시작 스테이지를 자동 감지한다."""
    wt = worktree_path(feature)
    jobs_dir = (wt / "jobs" / feature) if wt.exists() else (cfg.PROJECT_ROOT / "jobs" / feature)

    if not jobs_dir.exists():
        return "planner"

    file_set = {f.name for f in jobs_dir.iterdir() if f.is_file()}
    has_report = "report.md" in file_set
    has_plan = "implement-plan.md" in file_set

    if has_report and is_review_gate_pass(jobs_dir, "impl"):
        return "publisher"
    if is_review_gate_pass(jobs_dir, "impl"):
        return "reporter"
    if has_plan and is_review_gate_pass(jobs_dir, "plan"):
        return "implementor"
    return "planner"


def run_pipeline(
    feature: str,
    start_from: str | None = None,
    worktree_source: str = "local_head",
) -> None:
    """파이프라인을 실행한다.

    start_from 옵션:
      planner     - 전체 파이프라인 실행 (기본값). 새 워크트리 생성.
      implementor - Plan Review 루프를 건너뛰고 Implementor부터 시작 (기존 워크트리 사용)
      reporter    - Plan·Impl 루프를 건너뛰고 Reporter부터 시작 (기존 워크트리 사용)
      publisher   - Publisher만 실행 (기존 워크트리 사용)

    worktree_source 옵션:
      local_head  - 로컬 base branch HEAD를 기준으로 새 worktree 생성 (기본값)
      origin      - origin/<base-branch>를 fetch 후 기준으로 생성
    """
    if start_from is None:
        start_from = _auto_detect_start_from(feature)
        print(f"  Auto-detected start_from: {start_from}", flush=True)

    # ── 워크트리 설정 ──
    is_fresh = start_from == "planner" and not worktree_path(feature).exists()
    wt_path = create_worktree(feature, source=worktree_source) if is_fresh else ensure_worktree(feature)
    cfg.set_worktree_root(wt_path)

    # 에이전트가 워크트리 루트 기준 상대 경로를 사용하도록 cwd 설정
    os.chdir(cfg.PROJECT_ROOT)

    # 요구사항 파일 사전 검증 (+ source root fallback sync)
    _ensure_requirement_file(feature)

    # ── start-from 전제조건 검증 ──
    jobs_dir = cfg.JOBS_DIR / feature
    if start_from == "implementor":
        if not (jobs_dir / "implement-plan.md").exists():
            raise PipelineError(
                f"\n[ERROR] --start-from implementor 전제조건 파일이 없습니다:\n"
                f"  - jobs/{feature}/implement-plan.md"
            )
        _require_review_gate_for_start(jobs_dir, "plan", "implementor")

    if start_from == "reporter":
        _require_review_gate_for_start(jobs_dir, "impl", "reporter")

    if start_from == "publisher":
        if not (jobs_dir / "report.md").exists():
            raise PipelineError(
                f"\n[ERROR] --start-from publisher 전제조건 파일이 없습니다:\n"
                f"  - jobs/{feature}/report.md"
            )
        _require_review_gate_for_start(jobs_dir, "impl", "publisher")

    jobs_dir.mkdir(parents=True, exist_ok=True)
    manifest = PipelineManifestRecorder(jobs_dir=jobs_dir, feature=feature)
    manifest.set_context(
        start_from=start_from,
        worktree=str(wt_path),
        worktree_source=worktree_source,
        base_branch=cfg.BASE_BRANCH,
        remote=cfg.REMOTE,
    )

    stage_idx = _STAGE_ORDER.index(start_from)
    br = branch_name(feature)

    print(f"\nYaya Pipeline  feature={feature}  start_from={start_from}", flush=True)
    print(f"  Worktree: {wt_path}", flush=True)
    print(f"  Branch:   {br}", flush=True)
    print(f"  Worktree source: {worktree_source}", flush=True)

    try:
        if stage_idx <= _STAGE_ORDER.index("planner"):
            _run_plan_review_loop(feature, manifest=manifest)
        else:
            manifest.note_stage_status("plan_review", "skipped")

        if stage_idx <= _STAGE_ORDER.index("implementor"):
            _run_impl_review_loop(feature, manifest=manifest)
        else:
            manifest.note_stage_status("implementation_review", "skipped")

        if stage_idx <= _STAGE_ORDER.index("reporter"):
            _log("[REPORTER]", "reporter")
            manifest.note_stage_status("reporter", "running")
            stage_reporter(feature)
            manifest.note_stage_status("reporter", "passed")
        else:
            manifest.note_stage_status("reporter", "skipped")

        _log("[PUBLISHER]", "publisher")
        manifest.note_stage_status("publisher", "running")
        stage_publisher(feature, br)
        manifest.note_stage_status("publisher", "passed")

        manifest.finalize(status="completed")
        print("\nPipeline complete.", flush=True)
    except Exception as e:
        manifest.finalize(status="failed", error=str(e))
        raise
