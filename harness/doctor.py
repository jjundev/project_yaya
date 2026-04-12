"""Environment doctor for the iOS harness pipeline."""
from __future__ import annotations

import argparse
import importlib.util
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import harness.config as cfg


@dataclass
class CheckResult:
    name: str
    status: str  # PASS | WARN | FAIL
    message: str
    hint: str | None = None


def _check_python_version() -> CheckResult:
    required = (3, 10)
    current = sys.version_info[:3]
    if current >= required:
        return CheckResult(
            name="python.version",
            status="PASS",
            message=f"Python {current[0]}.{current[1]}.{current[2]}",
        )
    return CheckResult(
        name="python.version",
        status="FAIL",
        message=(
            f"Python {current[0]}.{current[1]}.{current[2]} is too old. "
            "PEP 604 type hints require Python >= 3.10."
        ),
        hint="`.venv/bin/python3 -m harness doctor`로 실행하거나 Python 3.10+를 사용하세요.",
    )


def _check_python_executable() -> CheckResult:
    executable = Path(sys.executable)
    resolved = executable.resolve()
    raw_path = str(executable).replace("\\", "/")
    if ".venv" in raw_path.split("/"):
        return CheckResult(
            name="python.executable",
            status="PASS",
            message=f"{executable} -> {resolved}",
        )
    return CheckResult(
        name="python.executable",
        status="WARN",
        message=f"non-venv interpreter in use: {resolved}",
        hint="재현성을 위해 `.venv/bin/python3` 사용을 권장합니다.",
    )


def _check_module(module_name: str) -> CheckResult:
    available = importlib.util.find_spec(module_name) is not None
    if available:
        return CheckResult(
            name=f"module.{module_name}",
            status="PASS",
            message="installed",
        )
    return CheckResult(
        name=f"module.{module_name}",
        status="FAIL",
        message="missing",
        hint="`pip install -r requirements.txt`를 실행하세요.",
    )


def _check_command(name: str, required: bool) -> CheckResult:
    path = shutil.which(name)
    if path:
        return CheckResult(
            name=f"command.{name}",
            status="PASS",
            message=path,
        )
    return CheckResult(
        name=f"command.{name}",
        status="FAIL" if required else "WARN",
        message="not found",
        hint=f"`{name}` 설치 후 PATH에 추가하세요.",
    )


def _git(*args: str) -> tuple[int, str, str]:
    r = subprocess.run(
        ["git", *args],
        cwd=cfg.PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def _check_base_branch_consistency() -> list[CheckResult]:
    checks: list[CheckResult] = []
    code, out, err = _git("rev-parse", "--verify", cfg.BASE_BRANCH)
    if code == 0:
        checks.append(
            CheckResult(
                name="git.local_base_branch",
                status="PASS",
                message=f"{cfg.BASE_BRANCH} exists locally",
            )
        )
    else:
        checks.append(
            CheckResult(
                name="git.local_base_branch",
                status="FAIL",
                message=f"local base branch `{cfg.BASE_BRANCH}` missing",
                hint=f"`git fetch {cfg.REMOTE} {cfg.BASE_BRANCH}` 후 다시 시도하세요.",
            )
        )

    code, out, err = _git("remote", "show", cfg.REMOTE)
    if code != 0:
        checks.append(
            CheckResult(
                name="git.remote_head",
                status="WARN",
                message=f"cannot inspect remote `{cfg.REMOTE}`: {err or out}",
            )
        )
        return checks

    head_line = next((line for line in out.splitlines() if "HEAD branch:" in line), "")
    remote_head = head_line.split("HEAD branch:", 1)[1].strip() if head_line else ""
    if not remote_head:
        checks.append(
            CheckResult(
                name="git.remote_head",
                status="WARN",
                message="unable to detect remote HEAD branch",
            )
        )
        return checks

    if remote_head == cfg.BASE_BRANCH:
        checks.append(
            CheckResult(
                name="git.remote_head",
                status="PASS",
                message=f"remote HEAD is `{remote_head}`",
            )
        )
    else:
        checks.append(
            CheckResult(
                name="git.remote_head",
                status="FAIL",
                message=(
                    f"remote HEAD is `{remote_head}` but harness BASE_BRANCH is "
                    f"`{cfg.BASE_BRANCH}`"
                ),
                hint="`harness/config.py`의 BASE_BRANCH 또는 원격 기본 브랜치를 일치시키세요.",
            )
        )

    return checks


def _check_launch_config(path: Path, label: str) -> CheckResult:
    if not path.exists():
        return CheckResult(
            name=f"launch.config.{label}",
            status="WARN",
            message=f"missing: {path}",
        )

    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        return CheckResult(
            name=f"launch.config.{label}",
            status="FAIL",
            message=f"invalid JSON: {e}",
        )

    configs = payload.get("configurations")
    if not isinstance(configs, list):
        return CheckResult(
            name=f"launch.config.{label}",
            status="FAIL",
            message="`configurations` field is missing or invalid",
        )

    runtime_exec = ""
    for cfg_item in configs:
        if isinstance(cfg_item, dict) and cfg_item.get("name") == "dashboard":
            runtime_exec = str(cfg_item.get("runtimeExecutable", "")).strip()
            break

    if not runtime_exec:
        return CheckResult(
            name=f"launch.config.{label}",
            status="WARN",
            message="dashboard runtimeExecutable not set",
        )

    if ".venv" in runtime_exec.replace("\\", "/"):
        return CheckResult(
            name=f"launch.config.{label}",
            status="PASS",
            message=f"dashboard runtimeExecutable={runtime_exec}",
        )

    return CheckResult(
        name=f"launch.config.{label}",
        status="WARN",
        message=f"dashboard runtimeExecutable should use .venv, found: {runtime_exec}",
        hint=f"`{path}`의 runtimeExecutable을 `.venv` python으로 변경하세요.",
    )


def _check_ios_makefile() -> CheckResult:
    makefile = cfg.PROJECT_ROOT / "ios" / "Yaya" / "Makefile"
    if not makefile.exists():
        return CheckResult(
            name="ios.makefile",
            status="WARN",
            message=f"missing: {makefile}",
        )

    content = makefile.read_text(encoding="utf-8")
    missing_targets: list[str] = []
    for target in ("test-unit:", "test-ui:"):
        if target not in content:
            missing_targets.append(target[:-1])

    if missing_targets:
        joined = ", ".join(missing_targets)
        return CheckResult(
            name="ios.makefile",
            status="FAIL",
            message=f"missing required targets: {joined}",
            hint="`ios/Yaya/Makefile`에 test-unit/test-ui 타겟을 추가하세요.",
        )

    return CheckResult(
        name="ios.makefile",
        status="PASS",
        message="contains test-unit/test-ui targets",
    )


def _check_pipeline_dirs() -> list[CheckResult]:
    checks: list[CheckResult] = []
    for rel in ("requirements", "jobs", "protocols"):
        path = cfg.PROJECT_ROOT / rel
        if path.exists() and path.is_dir():
            checks.append(
                CheckResult(
                    name=f"pipeline.dir.{rel}",
                    status="PASS",
                    message=str(path),
                )
            )
        else:
            checks.append(
                CheckResult(
                    name=f"pipeline.dir.{rel}",
                    status="FAIL",
                    message=f"missing: {path}",
                    hint=f"`{rel}/` 디렉터리를 생성하세요.",
                )
            )
    return checks


def _check_required_skills() -> list[CheckResult]:
    checks: list[CheckResult] = []
    claude_root = cfg.PROJECT_ROOT / ".claude" / "skills"

    if not claude_root.exists():
        checks.append(
            CheckResult(
                name="skills.claude",
                status="FAIL",
                message=f"missing: {claude_root}",
                hint="`.claude/skills`를 생성하고 역할별 SKILL.md를 추가하세요.",
            )
        )
        return checks

    required_roles = {"spector", "planner", "implementor", "reviewer", "reporter", "publisher"}
    missing_roles = [r for r in sorted(required_roles) if not (claude_root / r / "SKILL.md").exists()]
    if missing_roles:
        checks.append(
            CheckResult(
                name="skills.claude.required_roles",
                status="FAIL",
                message=f"missing role skills: {', '.join(missing_roles)}",
            )
        )
    else:
        checks.append(
            CheckResult(
                name="skills.claude.required_roles",
                status="PASS",
                message="spector/planner/implementor/reviewer/reporter/publisher present",
            )
        )
    return checks


def run_doctor(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python -m harness doctor",
        description="Harness 실행 환경 점검",
    )
    parser.add_argument("--json", action="store_true", help="JSON 형식으로 출력")
    args = parser.parse_args(argv or [])

    checks = collect_checks()

    if args.json:
        payload = {
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
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0 if payload["ok"] else 1

    print("\nHarness Doctor\n")
    for item in checks:
        icon = {"PASS": "PASS", "WARN": "WARN", "FAIL": "FAIL"}[item.status]
        print(f"[{icon}] {item.name}: {item.message}")
        if item.hint:
            print(f"       hint: {item.hint}")

    has_fail = any(c.status == "FAIL" for c in checks)
    if has_fail:
        print("\nDoctor result: FAIL")
        return 1
    print("\nDoctor result: PASS")
    return 0


def collect_checks() -> list[CheckResult]:
    checks: list[CheckResult] = []
    checks.append(_check_python_version())
    checks.append(_check_python_executable())
    checks.append(_check_module("claude_agent_sdk"))
    checks.append(_check_module("fastapi"))
    checks.append(_check_module("uvicorn"))

    checks.append(_check_command("git", required=True))
    checks.append(_check_command("gh", required=False))
    checks.append(_check_command("xcodebuild", required=False))
    checks.append(_check_command("xcrun", required=False))
    checks.append(_check_command("make", required=False))

    checks.extend(_check_base_branch_consistency())
    checks.append(_check_ios_makefile())
    checks.extend(_check_pipeline_dirs())

    checks.append(_check_launch_config(cfg.PROJECT_ROOT / ".claude" / "launch.json", "claude"))
    checks.extend(_check_required_skills())
    return checks
