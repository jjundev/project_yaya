"""Git worktree 생성·확인 유틸리티.

파이프라인 시작 시 기준 브랜치를 바탕으로 워크트리를 생성하고,
재개 시 기존 워크트리 존재를 확인한다.
"""
import functools
import subprocess
from datetime import datetime
from pathlib import Path

import harness.config as cfg
from harness.config import PipelineError


def _git(*args: str, cwd: Path) -> str:
    """git 명령을 실행하고 stdout을 반환한다. 실패 시 RuntimeError."""
    r = subprocess.run(
        ["git", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        raise RuntimeError(f"git {args[0]} failed:\n{r.stderr.strip()}")
    return r.stdout.strip()


@functools.lru_cache(maxsize=1)
def repo_root() -> Path:
    """메인 레포 루트를 반환한다. 워크트리 내부에서 실행해도 정확하다."""
    common_dir = _git("rev-parse", "--git-common-dir", cwd=Path.cwd())
    # --git-common-dir은 메인 .git 디렉토리를 반환. 그 부모가 레포 루트.
    return Path(common_dir).resolve().parent


def worktree_path(feature: str) -> Path:
    """feature에 해당하는 워크트리 경로를 반환한다."""
    return repo_root() / ".claude" / "worktrees" / feature


def branch_name(feature: str) -> str:
    """feature에 해당하는 브랜치명을 반환한다."""
    return f"codex/{feature}"


def _branch_exists(br: str, cwd: Path) -> bool:
    """로컬 브랜치가 존재하는지 확인한다."""
    try:
        _git("rev-parse", "--verify", br, cwd=cwd)
        return True
    except RuntimeError:
        return False


def _resolve_base_ref(root: Path, source: str) -> str:
    if source == "origin":
        _git("fetch", cfg.REMOTE, cfg.BASE_BRANCH, cwd=root)
        return f"{cfg.REMOTE}/{cfg.BASE_BRANCH}"

    if source == "local_head":
        if not _branch_exists(cfg.BASE_BRANCH, cwd=root):
            raise PipelineError(
                f"\n[ERROR] 로컬 base branch `{cfg.BASE_BRANCH}`가 없습니다.\n"
                f"  - `git fetch {cfg.REMOTE} {cfg.BASE_BRANCH}` 후 다시 시도하거나\n"
                f"  - `--from-origin` 옵션으로 실행하세요."
            )
        return cfg.BASE_BRANCH

    raise ValueError(f"Unknown worktree source: {source!r}")


def _create_backup_branch(root: Path, branch: str) -> str:
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    candidate = f"{branch}-backup-{timestamp}"
    suffix = 1
    while _branch_exists(candidate, cwd=root):
        suffix += 1
        candidate = f"{branch}-backup-{timestamp}-{suffix}"
    _git("branch", candidate, branch, cwd=root)
    return candidate


def create_worktree(feature: str, source: str = "local_head") -> Path:
    """기준 브랜치를 바탕으로 워크트리를 생성한다.

    이미 존재하면 안내 메시지와 함께 exit(1).
    브랜치가 이미 존재하면 백업 브랜치를 만든 뒤 기준 ref로 리셋한다.
    반환값: 생성된 워크트리의 절대 경로.
    """
    root = repo_root()
    wt = worktree_path(feature)
    br = branch_name(feature)

    if wt.exists():
        raise PipelineError(
            f"\n[ERROR] 워크트리가 이미 존재합니다: {wt}\n"
            f"  재개: python -m harness {feature} --start-from implementor\n"
            f"  삭제: git worktree remove {wt}"
        )

    # 디렉토리는 없지만 git에 등록만 남은 stale worktree 정리
    _git("worktree", "prune", cwd=root)
    base_ref = _resolve_base_ref(root, source)

    if _branch_exists(br, cwd=root):
        # 이전 실행에서 워크트리는 삭제했지만 브랜치가 남아있는 경우.
        # 데이터 유실 방지를 위해 reset 전에 백업 브랜치를 생성한다.
        backup_branch = _create_backup_branch(root, br)
        _git("worktree", "add", str(wt), br, cwd=root)
        _git("reset", "--hard", base_ref, cwd=wt)
        print(f"  Backup branch created: {backup_branch}", flush=True)
    else:
        _git(
            "worktree", "add", "-b", br,
            str(wt), base_ref,
            cwd=root,
        )

    print(f"  Worktree created: {wt}", flush=True)
    print(f"  Branch: {br}", flush=True)
    print(f"  Base ref: {base_ref} (source={source})", flush=True)
    return wt


def ensure_worktree(feature: str) -> Path:
    """기존 워크트리가 존재하는지 확인한다.

    존재하지 않으면 안내 메시지와 함께 exit(1).
    반환값: 워크트리의 절대 경로.
    """
    wt = worktree_path(feature)
    if not wt.exists():
        raise PipelineError(
            f"\n[ERROR] 워크트리가 없습니다: {wt}\n"
            f"  전체 실행: python -m harness {feature}"
        )
    return wt
