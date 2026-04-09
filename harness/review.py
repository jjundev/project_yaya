"""리뷰 결과 파일에서 PASS/FAIL을 판정하는 유틸리티."""
from __future__ import annotations

from dataclasses import dataclass
import re
import shutil
from pathlib import Path

_PLAN_FAIL_PREFIX = "review-plan"
_PLAN_PASS_PREFIX = "review-checklist"
_IMPL_PREFIX = "review-implement"

_PASS_PATTERNS = (
    r"##\s*Result\s*[:\-]\s*PASS",
    r"최종\s*판정\s*[:\-]\s*PASS",
    r"Verdict\s*[:\-]\s*PASS",
)
_FAIL_PATTERNS = (
    r"##\s*Result\s*[:\-]\s*FAIL",
    r"최종\s*판정\s*[:\-]\s*FAIL",
    r"Verdict\s*[:\-]\s*FAIL",
)

_CRITICAL_MARKER_RE = re.compile(r"\[(?:C|CRITICAL)-\d+[^\]]*\]", re.IGNORECASE)
_MAJOR_MARKER_RE = re.compile(r"\[(?:M|MAJOR)-\d+[^\]]*\]", re.IGNORECASE)
_MINOR_MARKER_RE = re.compile(r"\[(?:m|MINOR)-\d+[^\]]*\]", re.IGNORECASE)
_BLOCKING_MARKER_RE = re.compile(
    r"(?:\[(?:M|MAJOR)-\d+[^\]]*BLOCKING[^\]]*\]|MAJOR\s*\(\s*BLOCKING\s*\))",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class ReviewQuality:
    review_type: str
    review_file: Path | None
    result: str | None
    critical_count: int
    major_count: int
    minor_count: int
    blocking_major_count: int
    unit_test_status: str | None
    ui_test_status: str | None
    lint_status: str | None

    @property
    def has_unresolved_blockers(self) -> bool:
        return self.critical_count > 0 or self.major_count > 0


def _extract_version(path: Path, prefix: str) -> int | None:
    stem = path.stem
    base = f"{prefix}_"
    if not stem.startswith(base):
        return None
    suffix = stem[len(base):]
    if not suffix.isdigit():
        return None
    return int(suffix)


def _file_mtime_ns(path: Path) -> int:
    try:
        return path.stat().st_mtime_ns
    except OSError:
        return 0


def _collect_versioned_files(jobs_dir: Path, prefix: str) -> list[tuple[int, Path]]:
    if not jobs_dir.exists():
        return []
    matched: list[tuple[int, Path]] = []
    for path in jobs_dir.glob(f"{prefix}_*.md"):
        version = _extract_version(path, prefix)
        if version is not None:
            matched.append((version, path))
    return matched


def _latest_versioned_file(jobs_dir: Path, prefix: str) -> Path | None:
    candidates = _collect_versioned_files(jobs_dir, prefix)
    if not candidates:
        return None
    return max(candidates, key=lambda item: (item[0], _file_mtime_ns(item[1]), item[1].name))[1]


def _max_version(jobs_dir: Path, prefixes: tuple[str, ...]) -> int:
    max_version = 0
    for prefix in prefixes:
        for version, _ in _collect_versioned_files(jobs_dir, prefix):
            max_version = max(max_version, version)
    return max_version


def _review_result_from_content(content: str) -> str | None:
    for pat in _FAIL_PATTERNS:
        if re.search(pat, content, re.IGNORECASE):
            return "fail"
    for pat in _PASS_PATTERNS:
        if re.search(pat, content, re.IGNORECASE):
            return "pass"
    return None


def _extract_summary_count(content: str, label: str) -> int | None:
    m = re.search(rf"\b{re.escape(label)}\b\s*[:=]\s*(\d+)", content, re.IGNORECASE)
    if not m:
        return None
    return int(m.group(1))


def _extract_test_status(content: str, aliases: tuple[str, ...]) -> str | None:
    for alias in aliases:
        m = re.search(
            rf"{alias}[^\n\r]*\b(PASS|FAIL|SKIPPED|N/A)\b",
            content,
            re.IGNORECASE,
        )
        if m:
            return m.group(1).upper()
    return None


def _latest_plan_review_file(jobs_dir: Path) -> Path | None:
    candidates: list[tuple[int, int, str, Path]] = []
    for prefix in (_PLAN_FAIL_PREFIX, _PLAN_PASS_PREFIX):
        for version, path in _collect_versioned_files(jobs_dir, prefix):
            candidates.append((version, _file_mtime_ns(path), path.name, path))

    if candidates:
        return max(candidates, key=lambda item: (item[0], item[1], item[2]))[3]

    # Backward compatibility: 정적 파일만 있는 과거 산출물.
    checklist_alias = jobs_dir / f"{_PLAN_PASS_PREFIX}.md"
    fail_alias = jobs_dir / f"{_PLAN_FAIL_PREFIX}.md"
    alias_candidates = [p for p in (checklist_alias, fail_alias) if p.exists()]
    if not alias_candidates:
        return None
    return max(alias_candidates, key=lambda p: (_file_mtime_ns(p), p.name))


def _latest_plan_result(jobs_dir: Path) -> tuple[Path | None, str | None]:
    """(path, result) 반환. result는 'pass' | 'fail' | None."""
    path = _latest_plan_review_file(jobs_dir)
    if path is None:
        return None, None

    content = path.read_text(encoding="utf-8")
    result = _review_result_from_content(content)
    if result:
        return path, result

    # 결과 섹션이 누락된 legacy 문서는 파일명 prefix로 보정한다.
    if path.name.startswith(_PLAN_PASS_PREFIX):
        return path, "pass"
    if path.name.startswith(_PLAN_FAIL_PREFIX):
        return path, "fail"
    return path, None


def _is_impl_pass_from_path(review_file: Path) -> bool:
    if not review_file.exists():
        return False
    content = review_file.read_text(encoding="utf-8")
    return _review_result_from_content(content) == "pass"


def _latest_impl_result_file(jobs_dir: Path) -> Path | None:
    latest_impl = _latest_versioned_file(jobs_dir, _IMPL_PREFIX)
    if latest_impl:
        return latest_impl

    # Backward compatibility: 정적 파일만 있는 과거 산출물.
    alias = jobs_dir / f"{_IMPL_PREFIX}.md"
    if alias.exists():
        return alias
    return None


def next_review_version(jobs_dir: Path, review_type: str) -> int:
    """리뷰 타입별 다음 버전 번호(1-base)를 반환한다."""
    if review_type == "plan":
        return _max_version(jobs_dir, (_PLAN_FAIL_PREFIX, _PLAN_PASS_PREFIX)) + 1
    if review_type == "impl":
        return _max_version(jobs_dir, (_IMPL_PREFIX,)) + 1
    raise ValueError(f"Unknown review_type: {review_type!r}")


def sync_review_aliases(jobs_dir: Path, review_type: str) -> None:
    """최신 버전 파일을 legacy 고정 파일명(alias)으로 동기화한다."""
    if review_type == "plan":
        latest_fail = _latest_versioned_file(jobs_dir, _PLAN_FAIL_PREFIX)
        latest_pass = _latest_versioned_file(jobs_dir, _PLAN_PASS_PREFIX)
        if latest_fail:
            shutil.copyfile(latest_fail, jobs_dir / f"{_PLAN_FAIL_PREFIX}.md")
        if latest_pass:
            shutil.copyfile(latest_pass, jobs_dir / f"{_PLAN_PASS_PREFIX}.md")
        return

    if review_type == "impl":
        latest_impl = _latest_versioned_file(jobs_dir, _IMPL_PREFIX)
        if latest_impl:
            shutil.copyfile(latest_impl, jobs_dir / f"{_IMPL_PREFIX}.md")
        return

    raise ValueError(f"Unknown review_type: {review_type!r}")


def is_review_pass(jobs_dir: Path, review_type: str) -> bool:
    """리뷰 결과가 PASS인지 판정한다."""
    if review_type == "plan":
        _, result = _latest_plan_result(jobs_dir)
        return result == "pass"

    if review_type == "impl":
        review_file = _latest_impl_result_file(jobs_dir)
        if review_file is None:
            return False
        return _is_impl_pass_from_path(review_file)

    raise ValueError(f"Unknown review_type: {review_type!r}")


def evaluate_review_quality(jobs_dir: Path, review_type: str) -> ReviewQuality:
    """최신 리뷰 문서를 파싱해 severity/테스트 상태를 구조화한다."""
    if review_type == "plan":
        review_file, result = _latest_plan_result(jobs_dir)
    elif review_type == "impl":
        review_file = _latest_impl_result_file(jobs_dir)
        if review_file and review_file.exists():
            result = _review_result_from_content(review_file.read_text(encoding="utf-8"))
        else:
            result = None
    else:
        raise ValueError(f"Unknown review_type: {review_type!r}")

    if review_file is None or not review_file.exists():
        return ReviewQuality(
            review_type=review_type,
            review_file=None,
            result=None,
            critical_count=0,
            major_count=0,
            minor_count=0,
            blocking_major_count=0,
            unit_test_status=None,
            ui_test_status=None,
            lint_status=None,
        )

    content = review_file.read_text(encoding="utf-8")
    critical_count = _extract_summary_count(content, "Critical")
    major_count = _extract_summary_count(content, "Major")
    minor_count = _extract_summary_count(content, "Minor")

    if critical_count is None:
        critical_count = len(_CRITICAL_MARKER_RE.findall(content))
    if major_count is None:
        major_count = len(_MAJOR_MARKER_RE.findall(content))
    if minor_count is None:
        minor_count = len(_MINOR_MARKER_RE.findall(content))

    blocking_major_count = len(_BLOCKING_MARKER_RE.findall(content))
    if major_count < blocking_major_count:
        major_count = blocking_major_count

    return ReviewQuality(
        review_type=review_type,
        review_file=review_file,
        result=result,
        critical_count=critical_count,
        major_count=major_count,
        minor_count=minor_count,
        blocking_major_count=blocking_major_count,
        unit_test_status=_extract_test_status(
            content,
            aliases=(
                r"Unit\s*Test",
                r"XCTest",
                r"유닛\s*테스트",
            ),
        ),
        ui_test_status=_extract_test_status(
            content,
            aliases=(
                r"UI\s*Test",
                r"XCUITest",
                r"Espresso\s*UI\s*Test",
            ),
        ),
        lint_status=_extract_test_status(
            content,
            aliases=(
                r"\bLint\b",
                r"Lint\s*검사",
            ),
        ),
    )


def _format_hard_gate_feedback(quality: ReviewQuality) -> str:
    review_file = quality.review_file if quality.review_file else "(none)"
    return "\n".join(
        [
            "# Hard Quality Gate: FAIL",
            "",
            "## Result: FAIL",
            "- Severity: MAJOR(BLOCKING)",
            "- Category: Review Quality",
            "",
            "## Required Changes",
            (
                "1. 최신 리뷰 결과가 PASS인지 확인하세요."
                if quality.result != "pass"
                else "1. 최신 리뷰 결과는 PASS입니다."
            ),
            (
                f"2. Critical 이슈 {quality.critical_count}건을 모두 해소하세요."
                if quality.critical_count > 0
                else "2. Critical 이슈: 0건"
            ),
            (
                f"3. Major 이슈 {quality.major_count}건을 모두 해소하세요."
                if quality.major_count > 0
                else "3. Major 이슈: 0건"
            ),
            (
                f"4. Major(BLOCKING) 이슈 {quality.blocking_major_count}건을 모두 해소하세요."
                if quality.blocking_major_count > 0
                else "4. Major(BLOCKING) 이슈: 0건"
            ),
            "",
            "## Reference",
            f"- {review_file}",
        ]
    )


def check_hard_quality_gate(jobs_dir: Path, review_type: str) -> tuple[bool, str, ReviewQuality]:
    """최신 리뷰의 unresolved blocker(critical/major)를 차단한다."""
    quality = evaluate_review_quality(jobs_dir, review_type)
    if quality.review_file is None:
        return False, "Hard Quality Gate: review file not found.", quality

    if quality.result != "pass":
        return False, _format_hard_gate_feedback(quality), quality

    if quality.has_unresolved_blockers:
        return False, _format_hard_gate_feedback(quality), quality

    return True, "", quality


def is_review_gate_pass(jobs_dir: Path, review_type: str) -> bool:
    """PASS + unresolved blocker(critical/major) 0건일 때만 True."""
    passed, _, _ = check_hard_quality_gate(jobs_dir, review_type)
    return passed


def get_review_content(jobs_dir: Path, review_type: str) -> str:
    """최신 리뷰 파일의 내용을 반환한다. 파일이 없으면 빈 문자열."""
    if review_type == "plan":
        path, _ = _latest_plan_result(jobs_dir)
    elif review_type == "impl":
        path = _latest_impl_result_file(jobs_dir)
    else:
        raise ValueError(f"Unknown review_type: {review_type!r}")

    if path and path.exists():
        return path.read_text(encoding="utf-8")
    return ""


def get_latest_failed_review_content(jobs_dir: Path, review_type: str) -> str:
    """최신 판정이 FAIL인 경우에만 해당 리뷰 내용을 반환한다."""
    if review_type == "plan":
        path, result = _latest_plan_result(jobs_dir)
        if result == "fail" and path and path.exists():
            return path.read_text(encoding="utf-8")
        return ""

    if review_type == "impl":
        path = _latest_impl_result_file(jobs_dir)
        if path and path.exists() and not _is_impl_pass_from_path(path):
            return path.read_text(encoding="utf-8")
        return ""

    raise ValueError(f"Unknown review_type: {review_type!r}")
