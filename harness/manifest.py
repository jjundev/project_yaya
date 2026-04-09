"""Pipeline manifest recorder.

각 파이프라인 실행(run)의 상태를 jobs/<feature>/pipeline-manifest.json에 누적 기록한다.
"""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _safe_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(path.suffix + ".tmp")
    temp_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    os.replace(temp_path, path)


def _read_manifest(path: Path, feature: str) -> dict[str, Any]:
    if path.exists():
        try:
            parsed = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(parsed, dict):
                runs = parsed.get("runs")
                if isinstance(runs, list):
                    parsed.setdefault("feature", feature)
                    return parsed
        except Exception:
            pass
    return {"feature": feature, "runs": []}


class PipelineManifestRecorder:
    """현재 실행(run) 단위 manifest를 기록한다."""

    def __init__(self, jobs_dir: Path, feature: str) -> None:
        self._jobs_dir = jobs_dir
        self._path = jobs_dir / "pipeline-manifest.json"
        self._data = _read_manifest(self._path, feature)
        self._run: dict[str, Any] = {
            "id": f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{os.getpid()}",
            "feature": feature,
            "started_at": _utc_now(),
            "finished_at": None,
            "status": "running",
            "error": None,
            "context": {},
            "stages": {},
            "quality_gates": {},
            "ui_test_soft_gate": {},
        }
        self._data["runs"].append(self._run)
        self.flush()

    def flush(self) -> None:
        _safe_write_json(self._path, self._data)

    def set_context(self, **kwargs: Any) -> None:
        self._run["context"].update(kwargs)
        self.flush()

    def note_stage_attempt(self, stage: str, attempt: int, status: str, **details: Any) -> None:
        stage_entry = self._run["stages"].setdefault(stage, {"attempts": []})
        if "attempts" not in stage_entry:
            stage_entry["attempts"] = []
        entry = {
            "attempt": attempt,
            "status": status,
            "timestamp": _utc_now(),
            **details,
        }
        stage_entry["attempts"].append(entry)
        stage_entry["last_status"] = status
        self.flush()

    def note_stage_status(self, stage: str, status: str, **details: Any) -> None:
        stage_entry = self._run["stages"].setdefault(stage, {"attempts": []})
        stage_entry["status"] = status
        stage_entry["updated_at"] = _utc_now()
        stage_entry.update(details)
        self.flush()

    def note_quality_gate(
        self,
        review_type: str,
        *,
        passed: bool,
        feedback: str,
        quality: Any,
    ) -> None:
        self._run["quality_gates"][review_type] = {
            "passed": passed,
            "feedback": feedback,
            "review_file": str(quality.review_file) if getattr(quality, "review_file", None) else None,
            "result": getattr(quality, "result", None),
            "critical_count": int(getattr(quality, "critical_count", 0) or 0),
            "major_count": int(getattr(quality, "major_count", 0) or 0),
            "minor_count": int(getattr(quality, "minor_count", 0) or 0),
            "blocking_major_count": int(getattr(quality, "blocking_major_count", 0) or 0),
            "unit_test_status": getattr(quality, "unit_test_status", None),
            "ui_test_status": getattr(quality, "ui_test_status", None),
            "lint_status": getattr(quality, "lint_status", None),
            "updated_at": _utc_now(),
        }
        self.flush()

    def note_ui_test_gate(self, review_type: str, *, passed: bool, feedback: str) -> None:
        self._run["ui_test_soft_gate"][review_type] = {
            "passed": passed,
            "feedback": feedback,
            "updated_at": _utc_now(),
        }
        self.flush()

    def finalize(self, *, status: str, error: str | None = None) -> None:
        self._run["status"] = status
        self._run["error"] = error
        self._run["finished_at"] = _utc_now()
        self.flush()

