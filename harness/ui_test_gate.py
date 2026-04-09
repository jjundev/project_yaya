"""UI Test Requirement Soft Gate validators.

This module validates the markdown contract sections used by planner/reviewer/implementor
for iOS XCUITest omission prevention. Legacy Android contract keys are still accepted for
backward compatibility.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re

_SECTION_TITLE = "UI Test Requirement"
_REQUIRED_VALUES = {"YES", "NO"}
_TEST_FILE_SUFFIXES = (".swift", ".kt", ".java")


@dataclass(frozen=True)
class UITestRequirement:
    required: str
    reason: str
    trigger_ids: list[str]
    ui_test_paths: list[str]
    test_filter: str

    @property
    def is_required(self) -> bool:
        return self.required == "YES"


def validate_plan_ui_test_gate(project_root: Path, jobs_dir: Path) -> tuple[bool, str]:
    """Validate UI test contract in implement-plan.md.

    Returns:
        (passed, feedback). feedback is non-empty only when validation fails.
    """
    _ = project_root  # reserved for parity with impl validator signature
    plan_file = jobs_dir / "implement-plan.md"
    errors: list[str] = []

    if not plan_file.exists():
        errors.append(f"Missing file: {plan_file}")
    else:
        markdown = plan_file.read_text(encoding="utf-8")
        requirement, parse_errors = parse_ui_test_requirement(markdown)
        errors.extend(parse_errors)

        if requirement and requirement.is_required:
            errors.extend(_validate_plan_required_paths(markdown, requirement.ui_test_paths))

    if errors:
        return False, _format_feedback(
            stage="PLAN",
            reference_file=plan_file,
            errors=errors,
        )

    return True, ""


def validate_impl_ui_test_gate(project_root: Path, jobs_dir: Path) -> tuple[bool, str]:
    """Validate UI test contract in review-checklist.md + ui test file existence."""
    checklist_file = jobs_dir / "review-checklist.md"
    errors: list[str] = []

    if not checklist_file.exists():
        errors.append(f"Missing file: {checklist_file}")
    else:
        markdown = checklist_file.read_text(encoding="utf-8")
        requirement, parse_errors = parse_ui_test_requirement(markdown)
        errors.extend(parse_errors)

        if requirement and requirement.is_required:
            existing_targets: list[Path] = []
            for contract_path in requirement.ui_test_paths:
                resolved = _resolve_contract_path_targets(project_root, contract_path)
                if not resolved:
                    errors.append(
                        "Required=YES but contract path does not exist in workspace: "
                        f"{contract_path}"
                    )
                    continue
                existing_targets.extend(resolved)

            existing_targets = _deduplicate_paths(existing_targets)
            test_file_count = sum(_count_test_files(path) for path in existing_targets)
            if test_file_count == 0:
                errors.append(
                    "Required=YES but no *.swift/*.kt/*.java files were found under UI test paths."
                )

    if errors:
        return False, _format_feedback(
            stage="IMPLEMENTATION",
            reference_file=checklist_file,
            errors=errors,
        )

    return True, ""


def parse_ui_test_requirement(markdown: str) -> tuple[UITestRequirement | None, list[str]]:
    """Parse and validate the ## UI Test Requirement contract section."""
    section = _extract_h2_section(markdown, _SECTION_TITLE)
    if section is None:
        return None, [f"Missing required section: ## {_SECTION_TITLE}"]

    fields = _extract_key_values(section)
    required_raw = fields.get("required", "").strip().upper()
    reason = fields.get("reason", "").strip()
    trigger_ids = _split_csv(fields.get("trigger ids", ""))

    # iOS key 우선 + Android legacy key 하위호환
    raw_xcui_paths = fields.get("xcuitest paths", "")
    raw_legacy_paths = fields.get("androidtest paths", "")
    raw_paths = raw_xcui_paths or raw_legacy_paths
    ui_test_paths = _split_csv(raw_paths)

    test_filter = fields.get("test filter", "").strip()

    errors: list[str] = []

    if required_raw not in _REQUIRED_VALUES:
        errors.append("`Required` must be YES or NO.")

    if not reason:
        errors.append("`Reason` must not be empty.")

    if required_raw == "YES":
        if not trigger_ids:
            errors.append("`Trigger IDs` must not be empty when Required=YES.")
        if not ui_test_paths:
            errors.append("`XCUITest Paths` must not be empty when Required=YES (legacy: `AndroidTest Paths`).")
        if not test_filter or _is_na_value(test_filter):
            errors.append("`Test Filter` must not be empty when Required=YES.")

        for path in ui_test_paths:
            if not _has_valid_path_prefix(path):
                errors.append(
                    "UI test path must start with `ios/` (preferred) or `app/src/androidTest/` (legacy): "
                    f"{path}"
                )
    else:
        # Required=NO still requires explicit rationale and explicit non-applicability markers.
        if not fields.get("trigger ids", "").strip():
            errors.append("`Trigger IDs` must be explicitly provided (use N/A if not applicable).")
        if not (raw_xcui_paths.strip() or raw_legacy_paths.strip()):
            errors.append(
                "`XCUITest Paths` must be explicitly provided (use N/A if not applicable). "
                "(legacy key `AndroidTest Paths` is also accepted)"
            )
        if not fields.get("test filter", "").strip():
            errors.append("`Test Filter` must be explicitly provided (use N/A if not applicable).")

    if errors:
        return None, errors

    requirement = UITestRequirement(
        required=required_raw,
        reason=reason,
        trigger_ids=[] if _is_na_collection(trigger_ids) else trigger_ids,
        ui_test_paths=[] if _is_na_collection(ui_test_paths) else ui_test_paths,
        test_filter="" if _is_na_value(test_filter) else test_filter,
    )
    return requirement, []


def _validate_plan_required_paths(markdown: str, ui_test_paths: list[str]) -> list[str]:
    """Required=YES specific checks for implement-plan markdown."""
    errors: list[str] = []
    affected_files_section = _extract_h2_section(markdown, "Affected Files")

    for path in ui_test_paths:
        if not affected_files_section or path not in affected_files_section:
            errors.append(
                "Required=YES but UI test path is missing in `Affected Files`: "
                f"{path}"
            )

        if not _path_is_mentioned_in_step_block(markdown, path):
            errors.append(
                "Required=YES but no Implementation Step mentions UI test path: "
                f"{path}"
            )

    return errors


def _path_is_mentioned_in_step_block(markdown: str, target_path: str) -> bool:
    """Return True when a Step block explicitly references target_path."""
    step_pattern = re.compile(
        r"^###\s*Step\b.*?(?=^###\s*Step\b|^##\s+|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    for match in step_pattern.finditer(markdown):
        if target_path in match.group(0):
            return True
    return False


def _extract_h2_section(markdown: str, title: str) -> str | None:
    """Extract section content immediately following an H2 title."""
    heading = re.search(rf"^##\s+{re.escape(title)}\s*$", markdown, re.MULTILINE)
    if not heading:
        return None

    start = heading.end()
    next_heading = re.search(r"^##\s+", markdown[start:], re.MULTILINE)
    end = start + next_heading.start() if next_heading else len(markdown)
    return markdown[start:end].strip()


def _extract_key_values(section: str) -> dict[str, str]:
    """Extract simple key:value lines from markdown section."""
    result: dict[str, str] = {}
    for raw_line in section.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        line = re.sub(r"^[-*]\s*", "", line)
        line = line.replace("**", "")
        if ":" not in line:
            continue

        key, value = line.split(":", 1)
        result[_normalize_key(key)] = value.strip()

    return result


def _normalize_key(raw_key: str) -> str:
    lowered = raw_key.strip().lower()
    return re.sub(r"\s+", " ", lowered)


def _split_csv(raw_value: str) -> list[str]:
    if not raw_value:
        return []

    pieces = [p.strip() for p in re.split(r"\s*,\s*", raw_value.strip()) if p.strip()]
    return pieces


def _is_na_value(value: str) -> bool:
    return value.strip().upper() in {"N/A", "NA", "NONE", "-"}


def _is_na_collection(values: list[str]) -> bool:
    return len(values) == 1 and _is_na_value(values[0])


def _has_valid_path_prefix(path: str) -> bool:
    return path.startswith("ios/") or path.startswith("app/src/androidTest/")


def _resolve_contract_path_targets(project_root: Path, contract_path: str) -> list[Path]:
    """Resolve contract path against workspace root and common module roots."""
    if any(ch in contract_path for ch in "*?[]"):
        matches = list(project_root.glob(contract_path))
        matches.extend((project_root / "ios").glob(contract_path))
        matches.extend((project_root / "android").glob(contract_path))
        return [m for m in _deduplicate_paths(matches) if m.exists()]

    path = Path(contract_path)
    if path.is_absolute():
        return [path] if path.exists() else []

    candidates = [
        project_root / contract_path,
        project_root / "ios" / contract_path,
        project_root / "android" / contract_path,
    ]
    return [candidate for candidate in candidates if candidate.exists()]


def _deduplicate_paths(paths: list[Path]) -> list[Path]:
    unique: list[Path] = []
    seen: set[str] = set()
    for path in paths:
        key = str(path.resolve()) if path.exists() else str(path)
        if key in seen:
            continue
        seen.add(key)
        unique.append(path)
    return unique


def _count_test_files(path: Path) -> int:
    if path.is_file():
        return 1 if path.suffix in _TEST_FILE_SUFFIXES else 0

    count = 0
    for suffix in _TEST_FILE_SUFFIXES:
        count += sum(1 for _ in path.rglob(f"*{suffix}"))
    return count


def _format_feedback(stage: str, reference_file: Path, errors: list[str]) -> str:
    lines = [
        f"# UI Test Soft Gate: FAIL ({stage})",
        "",
        "## Result: FAIL",
        "- Severity: MAJOR(BLOCKING)",
        "- Category: UI Test Requirement Contract",
        "",
        "## Required Changes",
    ]
    for idx, error in enumerate(errors, start=1):
        lines.append(f"{idx}. {error}")

    lines.extend(
        [
            "",
            "## Reference",
            f"- {reference_file}",
        ]
    )
    return "\n".join(lines)
