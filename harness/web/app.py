"""FastAPI 대시보드 서버.

REST API + WebSocket으로 파이프라인을 제어하고 모니터링한다.
"""
from __future__ import annotations

import asyncio
import os
import signal as _signal
from pathlib import Path

import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel

from harness.doctor import collect_checks
from harness.pipeline import _auto_detect_start_from
from harness.pr_status import PullRequestState, fetch_feature_pr_states
from harness.review import check_hard_quality_gate, evaluate_review_quality, is_review_gate_pass
from harness.web.runner import PipelineRunner, PipelineStatus
from harness.worktree import repo_root, worktree_path

app = FastAPI(title="Yaya Pipeline Dashboard")
runner = PipelineRunner()

_SHUTDOWN_GRACE_SEC = 30.0
_active_ws_count: int = 0
_shutdown_task: asyncio.Task | None = None


async def _shutdown_after_delay() -> None:
    await asyncio.sleep(_SHUTDOWN_GRACE_SEC)
    os.kill(os.getpid(), _signal.SIGTERM)


async def _maybe_schedule_shutdown() -> None:
    global _shutdown_task
    if _active_ws_count > 0:
        return
    if runner.status in (PipelineStatus.RUNNING, PipelineStatus.STOPPING):
        return
    if _shutdown_task and not _shutdown_task.done():
        return
    _shutdown_task = asyncio.create_task(_shutdown_after_delay())


def _on_pipeline_status_change(status: PipelineStatus) -> None:
    if _active_ws_count == 0:
        asyncio.ensure_future(_maybe_schedule_shutdown())


runner.on_status_change = _on_pipeline_status_change

# 프로젝트 루트 — 어느 워크트리에서 실행해도 메인 레포 루트를 가리킨다.
_PROJECT_ROOT = repo_root()
_DASHBOARD_HTML = Path(__file__).resolve().parent / "dashboard.html"


def _jobs_dir(feature: str) -> Path:
    """워크트리가 존재하면 그 안의 jobs 디렉토리를, 아니면 프로젝트 루트의 jobs 디렉토리를 반환."""
    wt = worktree_path(feature)
    if wt.exists():
        return wt / "jobs" / feature
    return _PROJECT_ROOT / "jobs" / feature


def _is_requirement_completed(feature: str, pr_states: dict[str, PullRequestState]) -> bool:
    """feature에 해당하는 작업이 완료(merged/closed)되었는지 확인한다."""
    state = pr_states.get(feature)
    if state is None:
        return False
    return state.is_terminal


class StartRequest(BaseModel):
    feature: str
    max_gan: int = 3
    start_from: str | None = None
    worktree_source: str = "local_head"


def _review_risk_payload(feature: str, review_type: str) -> dict:
    jobs_dir = _jobs_dir(feature)
    quality = evaluate_review_quality(jobs_dir, review_type)
    gate_passed, gate_feedback, _ = check_hard_quality_gate(jobs_dir, review_type)
    return {
        "review_type": review_type,
        "review_file": str(quality.review_file) if quality.review_file else None,
        "result": quality.result,
        "critical_count": quality.critical_count,
        "major_count": quality.major_count,
        "minor_count": quality.minor_count,
        "blocking_major_count": quality.blocking_major_count,
        "gate_passed": gate_passed,
        "gate_feedback": gate_feedback,
        "unit_test_status": quality.unit_test_status,
        "ui_test_status": quality.ui_test_status,
        "lint_status": quality.lint_status,
    }


def _doctor_payload() -> dict:
    checks = collect_checks()
    return {
        "ok": not any(c.status == "FAIL" for c in checks),
        "checks": [
            {
                "name": c.name,
                "status": c.status,
                "message": c.message,
                "hint": c.hint,
            }
            for c in checks
        ],
    }


@app.get("/", response_class=HTMLResponse)
async def serve_dashboard():
    return _DASHBOARD_HTML.read_text(encoding="utf-8")


@app.get("/api/requirements")
async def list_requirements():
    req_dir = _PROJECT_ROOT / "requirements"
    if not req_dir.exists():
        return {"requirements": []}
    pr_states = fetch_feature_pr_states(_PROJECT_ROOT)
    items = []
    for f in sorted(req_dir.glob("requirement_*.md")):
        name = f.stem.replace("requirement_", "")
        if _is_requirement_completed(name, pr_states):
            continue
        items.append({"name": name, "file": f.name})
    return {"requirements": items}


@app.get("/api/doctor")
async def doctor_status():
    return _doctor_payload()


@app.get("/api/jobs/{feature}")
async def check_job_status(feature: str):
    jobs_dir = _jobs_dir(feature)
    if not jobs_dir.exists():
        return {
            "feature": feature,
            "exists": False,
            "files": [],
            "resume_from": "planner",
            "can_resume": False,
            "risk": {
                "plan": _review_risk_payload(feature, "plan"),
                "impl": _review_risk_payload(feature, "impl"),
            },
        }

    files = sorted(f.name for f in jobs_dir.iterdir() if f.is_file())
    file_set = set(files)

    resume_from = "planner"
    can_resume = False
    has_report = "report.md" in file_set
    has_plan = "implement-plan.md" in file_set

    # publisher 전제조건: report.md + latest impl review PASS
    if has_report and is_review_gate_pass(jobs_dir, "impl"):
        resume_from = "publisher"
        can_resume = True
    # reporter 전제조건: latest impl review PASS
    elif is_review_gate_pass(jobs_dir, "impl"):
        resume_from = "reporter"
        can_resume = True
    # implementor 전제조건: implement-plan.md + latest plan review PASS
    elif has_plan and is_review_gate_pass(jobs_dir, "plan"):
        resume_from = "implementor"
        can_resume = True

    return {
        "feature": feature,
        "exists": True,
        "files": files,
        "resume_from": resume_from,
        "can_resume": can_resume,
        "risk": {
            "plan": _review_risk_payload(feature, "plan"),
            "impl": _review_risk_payload(feature, "impl"),
        },
    }


@app.post("/api/pipeline/start")
async def start_pipeline(req: StartRequest):
    if runner.status == PipelineStatus.RUNNING:
        return JSONResponse(
            status_code=409,
            content={"error": "Pipeline already running"},
        )
    if runner.status == PipelineStatus.STOPPING:
        return JSONResponse(
            status_code=409,
            content={"error": "Pipeline is stopping. Please wait until it becomes idle."},
        )

    if req.worktree_source not in {"local_head", "origin"}:
        return JSONResponse(
            status_code=400,
            content={"error": "Invalid worktree_source. Use `local_head` or `origin`."},
        )

    # 자동 resume 판정
    start_from = req.start_from
    if not start_from:
        start_from = _auto_detect_start_from(req.feature)

    try:
        await runner.start(req.feature, start_from, req.max_gan, req.worktree_source)
    except RuntimeError as e:
        msg = str(e)
        return JSONResponse(status_code=409, content={"error": msg})

    return {
        "status": "started",
        "feature": req.feature,
        "start_from": start_from,
        "worktree_source": req.worktree_source,
    }


@app.post("/api/pipeline/stop")
async def stop_pipeline():
    if runner.status == PipelineStatus.STOPPING:
        return JSONResponse(
            status_code=409,
            content={"error": "Pipeline is already stopping"},
        )
    if runner.status != PipelineStatus.RUNNING:
        return JSONResponse(
            status_code=409,
            content={"error": "Pipeline not running"},
        )

    try:
        termination = await runner.stop()
    except RuntimeError as e:
        msg = str(e)
        if msg in {"Pipeline not running", "Pipeline is already stopping"}:
            return JSONResponse(status_code=409, content={"error": msg})
        return JSONResponse(status_code=500, content={"error": msg})

    return {"status": "stopped", "termination": termination}


@app.get("/api/pipeline/status")
async def pipeline_status():
    return runner.get_state()


@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    global _active_ws_count, _shutdown_task
    _active_ws_count += 1
    if _shutdown_task and not _shutdown_task.done():
        _shutdown_task.cancel()
        _shutdown_task = None

    await ws.accept()
    queue = runner.subscribe()

    # 초기 상태 전송
    import json
    await ws.send_text(json.dumps(runner.get_state(), ensure_ascii=False))

    try:
        while True:
            try:
                msg = await asyncio.wait_for(queue.get(), timeout=30.0)
                await ws.send_text(msg)
            except asyncio.TimeoutError:
                # keepalive ping
                await ws.send_text('{"type":"ping"}')
    except WebSocketDisconnect:
        pass
    finally:
        runner.unsubscribe(queue)
        _active_ws_count -= 1
        await _maybe_schedule_shutdown()


def start_server(port: int = 8420) -> None:
    print(f"\n  Yaya Pipeline Dashboard")
    print(f"  http://localhost:{port}\n")
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="warning")
