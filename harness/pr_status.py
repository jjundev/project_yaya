"""GitHub PR 상태 조회 유틸리티."""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
import shutil
import subprocess


@dataclass(frozen=True)
class PullRequestState:
    feature: str
    state: str  # open | closed | merged
    number: int | None
    url: str | None
    updated_at: str | None

    @property
    def is_terminal(self) -> bool:
        return self.state in {"closed", "merged"}


def _parse_feature_from_head_ref(head_ref: str | None) -> str | None:
    if not head_ref:
        return None
    for prefix in ("codex/", "feature/"):
        if head_ref.startswith(prefix):
            feature = head_ref[len(prefix):].strip()
            if feature:
                return feature
    return None


def _classify_state(item: dict) -> str:
    merged_at = item.get("mergedAt")
    if isinstance(merged_at, str) and merged_at.strip():
        return "merged"

    raw = str(item.get("state", "")).upper().strip()
    if raw == "MERGED":
        return "merged"
    if raw == "CLOSED":
        return "closed"
    return "open"


def _build_state(item: dict) -> PullRequestState | None:
    feature = _parse_feature_from_head_ref(item.get("headRefName"))
    if feature is None:
        return None

    number_raw = item.get("number")
    number = int(number_raw) if isinstance(number_raw, int) else None
    url = item.get("url")
    updated_at = item.get("updatedAt")

    return PullRequestState(
        feature=feature,
        state=_classify_state(item),
        number=number,
        url=url if isinstance(url, str) else None,
        updated_at=updated_at if isinstance(updated_at, str) else None,
    )


def _is_newer(candidate: PullRequestState, current: PullRequestState) -> bool:
    # GitHub API timestamp는 ISO8601(UTC) 문자열이므로 문자열 비교가 시간순과 동일하다.
    if candidate.updated_at and current.updated_at:
        return candidate.updated_at > current.updated_at
    if candidate.updated_at and not current.updated_at:
        return True
    return False


def fetch_feature_pr_states(project_root: Path, limit: int = 200) -> dict[str, PullRequestState]:
    """현재 저장소의 feature/<name> PR 상태를 feature 기준으로 반환한다."""
    if shutil.which("gh") is None:
        return {}

    cmd = [
        "gh",
        "pr",
        "list",
        "--state",
        "all",
        "--limit",
        str(limit),
        "--json",
        "number,state,mergedAt,url,headRefName,updatedAt",
    ]
    proc = subprocess.run(
        cmd,
        cwd=project_root,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return {}

    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return {}

    if not isinstance(payload, list):
        return {}

    result: dict[str, PullRequestState] = {}
    for item in payload:
        if not isinstance(item, dict):
            continue
        state = _build_state(item)
        if state is None:
            continue
        current = result.get(state.feature)
        if current is None or _is_newer(state, current):
            result[state.feature] = state
    return result
