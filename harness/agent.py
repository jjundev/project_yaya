"""Claude Agent SDK 기반 에이전트 실행기.

각 스킬의 SKILL.md를 시스템 프롬프트로 주입하고,
ClaudeAgentOptions로 모델·허용 도구를 제어한다.
"""
from __future__ import annotations

import asyncio
from pathlib import Path

try:  # pragma: no cover - optional runtime dependency
    from claude_agent_sdk import AssistantMessage, ClaudeAgentOptions, ResultMessage, query
    _SDK_IMPORT_ERROR: Exception | None = None
except Exception as e:  # pragma: no cover - optional runtime dependency
    AssistantMessage = None  # type: ignore[assignment]
    ClaudeAgentOptions = None  # type: ignore[assignment]
    ResultMessage = None  # type: ignore[assignment]
    query = None  # type: ignore[assignment]
    _SDK_IMPORT_ERROR = e

import harness.config as cfg


def _source_skills_dir() -> Path:
    return Path(__file__).resolve().parent.parent / ".claude" / "skills"


def load_skill(name: str) -> str:
    """지정된 스킬의 SKILL.md 내용을 반환한다."""
    skill_rel = Path(name) / "SKILL.md"
    primary = cfg.SKILLS_DIR / skill_rel
    if primary.exists():
        return primary.read_text(encoding="utf-8")

    # worktree에 스킬이 아직 반영되지 않은 경우, 실행 소스 트리의 스킬로 fallback.
    fallback = _source_skills_dir() / skill_rel
    if fallback.exists():
        return fallback.read_text(encoding="utf-8")

    raise FileNotFoundError(f"Skill file not found: {primary}")


async def _run_async(skill_name: str, user_message: str) -> str:
    if _SDK_IMPORT_ERROR is not None:
        raise RuntimeError(
            "claude_agent_sdk is not available. "
            "Install dependencies with `pip install -r requirements.txt`."
        ) from _SDK_IMPORT_ERROR

    options = ClaudeAgentOptions(
        model=cfg.MODELS[skill_name],
        system_prompt=load_skill(skill_name),
        allowed_tools=cfg.AGENT_TOOLS[skill_name],
        permission_mode="acceptEdits",
        cwd=cfg.PROJECT_ROOT,
    )

    collected: list[str] = []
    async for message in query(prompt=user_message, options=options):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                text = getattr(block, "text", None)
                if text:
                    collected.append(text)
        elif isinstance(message, ResultMessage):
            if message.is_error:
                raise RuntimeError(
                    f"Agent '{skill_name}' failed (subtype={message.subtype})"
                )

    return "\n".join(collected)


def run_agent(skill_name: str, user_message: str) -> None:
    """동기 진입점 — 내부적으로 asyncio.run()을 사용한다."""
    asyncio.run(_run_async(skill_name, user_message))
