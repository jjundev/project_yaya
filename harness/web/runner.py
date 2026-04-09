"""파이프라인 서브프로세스 실행기.

파이프라인을 별도 프로세스로 실행하고 stdout/stderr를 실시간으로 파싱하여
WebSocket 구독자에게 브로드캐스트한다.

Windows에서 uvicorn의 이벤트 루프와 asyncio subprocess가 호환되지 않으므로
subprocess.Popen + 스레드 방식으로 구현한다.
"""
from __future__ import annotations

import asyncio
import json
import os
import re
import signal
import subprocess
import sys
import threading
from datetime import datetime
from enum import Enum
from dataclasses import dataclass
from typing import Callable, Optional


class PipelineStatus(str, Enum):
    IDLE = "idle"
    RUNNING = "running"
    STOPPING = "stopping"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class StageInfo:
    name: str
    display: str
    status: str = "pending"  # pending | active | passed | failed | skipped


# 6개 시각적 스테이지 (roadmap 표시용)
STAGE_DEFINITIONS = [
    ("planner", "Planner"),
    ("reviewer_plan", "Reviewer (Plan)"),
    ("implementor", "Implementor"),
    ("reviewer_impl", "Reviewer (Impl)"),
    ("reporter", "Reporter"),
    ("publisher", "Publisher"),
]


def _make_stages() -> list[StageInfo]:
    return [StageInfo(name=n, display=d) for n, d in STAGE_DEFINITIONS]


# stdout 파싱 패턴 (pipeline.py _log() 출력 기준)
_STAGE_RE = re.compile(
    r"\[(\w+(?:\s+\w+)?)\](?:\s+attempt\s+(\d+)/(\d+))?"
)
_PASS_RE = re.compile(r"→\s*PASS")
_FAIL_RE = re.compile(r"→\s*FAIL\s*(?:\(attempt\s+(\d+)/(\d+)\))?")
_COMPLETE_RE = re.compile(r"Pipeline complete\.")

# 파이프라인 출력의 스테이지 레이블 → 내부 이름 매핑
_LABEL_MAP = {
    "PLANNER": "planner",
    "REVIEWER PLAN": "reviewer_plan",
    "IMPLEMENTOR": "implementor",
    "REVIEWER IMPL": "reviewer_impl",
    "REPORTER": "reporter",
    "PUBLISHER": "publisher",
}


_GRACEFUL_STOP_TIMEOUT_SEC = 5.0
_FORCE_STOP_TIMEOUT_SEC = 5.0


class PipelineRunner:
    """파이프라인 서브프로세스 생명주기를 관리한다."""

    def __init__(self) -> None:
        self.status: PipelineStatus = PipelineStatus.IDLE
        self.feature: str = ""
        self.max_gan: int = 3
        self.worktree_source: str = "local_head"
        self.current_stage: str = ""
        self.gan_iteration: int = 0
        self.gan_phase: str = ""  # "plan" | "impl"
        self.stages: list[StageInfo] = _make_stages()
        self.error: Optional[str] = None
        self._process: Optional[subprocess.Popen] = None
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._subscribers: list[asyncio.Queue] = []
        self._stop_event: Optional[asyncio.Event] = None
        self._stop_termination: Optional[str] = None
        self._proc_lock = threading.Lock()
        self.on_status_change: Optional[Callable[["PipelineStatus"], None]] = None

    def subscribe(self) -> asyncio.Queue:
        q: asyncio.Queue = asyncio.Queue()
        self._subscribers.append(q)
        return q

    def unsubscribe(self, q: asyncio.Queue) -> None:
        if q in self._subscribers:
            self._subscribers.remove(q)

    def _enqueue(self, msg: dict) -> None:
        """스레드에서 안전하게 WebSocket 큐에 메시지를 넣는다."""
        data = json.dumps(msg, ensure_ascii=False)
        for q in self._subscribers:
            try:
                if self._loop and self._loop.is_running():
                    self._loop.call_soon_threadsafe(q.put_nowait, data)
            except (RuntimeError, asyncio.QueueFull):
                pass

    async def start(
        self,
        feature: str,
        start_from: str,
        max_gan: int,
        worktree_source: str = "local_head",
    ) -> None:
        if self.status in (PipelineStatus.RUNNING, PipelineStatus.STOPPING):
            raise RuntimeError("Pipeline already running")
        with self._proc_lock:
            if self._process is not None:
                raise RuntimeError("Pipeline process is still active")

        self.feature = feature
        self.max_gan = max_gan
        self.worktree_source = worktree_source
        self.error = None
        self.stages = _make_stages()
        self.current_stage = ""
        self.gan_iteration = 0
        self.gan_phase = ""
        self.status = PipelineStatus.RUNNING
        self._loop = asyncio.get_running_loop()
        self._stop_event = asyncio.Event()
        self._stop_termination = None

        # skip 처리: start_from 이전 스테이지는 skipped
        stage_names = [s.name for s in self.stages]
        if start_from in _LABEL_MAP.values():
            idx = stage_names.index(start_from)
            for s in self.stages[:idx]:
                s.status = "skipped"

        self._enqueue(self._status_msg())
        self._enqueue(self._stage_msg())

        env = os.environ.copy()
        env["HARNESS_MAX_GAN"] = str(max_gan)
        env["PYTHONIOENCODING"] = "utf-8"
        env["PYTHONUNBUFFERED"] = "1"

        # harness/web/runner.py → harness/web → harness → project root
        project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        cmd = [sys.executable, "-m", "harness", feature, "--start-from", start_from]
        if worktree_source == "origin":
            cmd.append("--from-origin")
        else:
            cmd.append("--from-local-head")

        popen_kwargs: dict = {
            "stdout": subprocess.PIPE,
            "stderr": subprocess.PIPE,
            "env": env,
            "cwd": project_root,
        }
        if os.name == "nt":
            popen_kwargs["creationflags"] = getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
        else:
            popen_kwargs["start_new_session"] = True

        proc = subprocess.Popen(cmd, **popen_kwargs)
        with self._proc_lock:
            self._process = proc

        # 스레드에서 stdout/stderr 읽기 + 프로세스 종료 대기
        threading.Thread(
            target=self._run_in_thread,
            args=(proc, self._stop_event),
            daemon=True,
        ).start()

    async def stop(self) -> str:
        if self.status == PipelineStatus.STOPPING:
            raise RuntimeError("Pipeline is already stopping")
        with self._proc_lock:
            proc = self._process
        if proc is None or self.status != PipelineStatus.RUNNING:
            raise RuntimeError("Pipeline not running")
        if self._stop_event is None:
            raise RuntimeError("Pipeline stop synchronization is not initialized")

        self.status = PipelineStatus.STOPPING
        self._enqueue(self._status_msg())
        self._stop_termination = None

        self._terminate_process_tree(proc)

        try:
            await asyncio.wait_for(self._stop_event.wait(), timeout=_GRACEFUL_STOP_TIMEOUT_SEC)
            self._stop_termination = "graceful"
            return self._stop_termination
        except asyncio.TimeoutError:
            pass

        self._kill_process_tree(proc)
        try:
            await asyncio.wait_for(self._stop_event.wait(), timeout=_FORCE_STOP_TIMEOUT_SEC)
        except asyncio.TimeoutError as e:
            self.error = "Failed to stop pipeline process within timeout"
            self._enqueue(self._status_msg())
            raise RuntimeError("Failed to stop pipeline process") from e

        self._stop_termination = "forced"
        return self._stop_termination

    def _run_in_thread(self, proc: subprocess.Popen, stop_event: Optional[asyncio.Event]) -> None:
        """별도 스레드에서 subprocess stdout/stderr를 읽고 파싱한다."""
        def read_stream(stream, is_stderr: bool) -> None:
            for raw in stream:
                line = raw.decode("utf-8", errors="replace").rstrip("\n\r")
                if not line:
                    continue
                if not is_stderr:
                    self._parse_line(line)
                self._enqueue({
                    "type": "log",
                    "line": line,
                    "stream": "stderr" if is_stderr else "stdout",
                    "timestamp": datetime.now().isoformat(timespec="seconds"),
                })

        t_out = threading.Thread(target=read_stream, args=(proc.stdout, False), daemon=True)
        t_err = threading.Thread(target=read_stream, args=(proc.stderr, True), daemon=True)
        t_out.start()
        t_err.start()

        t_out.join()
        t_err.join()
        code = proc.wait()

        with self._proc_lock:
            if self._process is proc:
                self._process = None

        if self.status == PipelineStatus.STOPPING:
            self.status = PipelineStatus.IDLE
            self._enqueue(self._status_msg())
            self._notify_status_change()
            self._signal_stop_event(stop_event)
            return

        if code == 0:
            self.status = PipelineStatus.COMPLETED
        else:
            self.status = PipelineStatus.FAILED
            if self.current_stage:
                for s in self.stages:
                    if s.name == self.current_stage and s.status == "active":
                        s.status = "failed"
            self.error = f"Process exited with code {code}"

        self._enqueue(self._stage_msg())
        self._enqueue(self._status_msg())
        self._notify_status_change()
        self._signal_stop_event(stop_event)

    def _notify_status_change(self) -> None:
        if self.on_status_change and self._loop and self._loop.is_running():
            try:
                self._loop.call_soon_threadsafe(self.on_status_change, self.status)
            except RuntimeError:
                pass

    def _signal_stop_event(self, stop_event: Optional[asyncio.Event]) -> None:
        if stop_event is None:
            return
        if self._loop and self._loop.is_running():
            try:
                self._loop.call_soon_threadsafe(stop_event.set)
            except RuntimeError:
                pass

    def _terminate_process_tree(self, proc: subprocess.Popen) -> None:
        if proc.poll() is not None:
            return
        if os.name == "nt":
            subprocess.run(
                ["taskkill", "/PID", str(proc.pid), "/T"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            return
        try:
            os.killpg(proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            return
        except OSError:
            proc.terminate()

    def _kill_process_tree(self, proc: subprocess.Popen) -> None:
        if proc.poll() is not None:
            return
        if os.name == "nt":
            subprocess.run(
                ["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            return
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            return
        except OSError:
            proc.kill()

    def _parse_line(self, line: str) -> None:
        # 스테이지 헤더 감지
        m = _STAGE_RE.search(line)
        if m:
            label = m.group(1)
            attempt = int(m.group(2)) if m.group(2) else 0
            stage_name = _LABEL_MAP.get(label)
            if stage_name:
                self.current_stage = stage_name
                self.gan_iteration = attempt
                if stage_name in ("planner", "reviewer_plan"):
                    self.gan_phase = "plan"
                elif stage_name in ("implementor", "reviewer_impl"):
                    self.gan_phase = "impl"
                else:
                    self.gan_phase = ""

                for s in self.stages:
                    if s.name == stage_name:
                        s.status = "active"
                    elif s.status == "active":
                        s.status = "passed"

                self._enqueue(self._stage_msg())
            return

        # PASS 감지
        if _PASS_RE.search(line):
            for s in self.stages:
                if s.name == self.current_stage and s.status == "active":
                    s.status = "passed"
            self._enqueue(self._stage_msg())
            return

        # FAIL 감지
        if _FAIL_RE.search(line):
            for s in self.stages:
                if s.name == self.current_stage and s.status == "active":
                    s.status = "failed"
            self._enqueue(self._stage_msg())
            return

        # 완료 감지
        if _COMPLETE_RE.search(line):
            if self.status == PipelineStatus.STOPPING:
                return
            self.status = PipelineStatus.COMPLETED
            for s in self.stages:
                if s.status == "active":
                    s.status = "passed"
            self._enqueue(self._stage_msg())
            self._enqueue(self._status_msg())

    def _stage_msg(self) -> dict:
        return {
            "type": "stage",
            "stages": [
                {"name": s.name, "display": s.display, "status": s.status}
                for s in self.stages
            ],
            "current": self.current_stage,
            "gan_iteration": self.gan_iteration,
            "gan_phase": self.gan_phase,
            "max_gan": self.max_gan,
        }

    def _status_msg(self) -> dict:
        return {
            "type": "status",
            "status": self.status.value,
            "feature": self.feature,
            "error": self.error,
            "termination": self._stop_termination,
            "worktree_source": self.worktree_source,
        }

    def get_state(self) -> dict:
        return {
            **self._status_msg(),
            **self._stage_msg(),
        }
