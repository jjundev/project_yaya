from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys
import types
from unittest import mock

# Test 환경에서 optional dependency(claude_agent_sdk)가 없더라도
# harness.pipeline import가 가능하도록 최소 스텁을 주입한다.
if "claude_agent_sdk" not in sys.modules:
    stub = types.ModuleType("claude_agent_sdk")
    stub.AssistantMessage = type("AssistantMessage", (), {})
    stub.ClaudeAgentOptions = type("ClaudeAgentOptions", (), {})
    stub.ResultMessage = type("ResultMessage", (), {})

    async def _query_stub(*_args, **_kwargs):  # pragma: no cover - import stub only
        if False:
            yield None

    stub.query = _query_stub
    sys.modules["claude_agent_sdk"] = stub

import harness.config as cfg
import harness.pipeline as pipeline
from harness.review import (
    check_hard_quality_gate,
    evaluate_review_quality,
    is_review_pass,
)


class ReviewQualityParserTests(unittest.TestCase):
    def test_impl_pass_with_major_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            jobs_dir = Path(td) / "jobs" / "feature-a"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "review-implement.md").write_text(
                """# Implementation Review

## Result: PASS

## Review Summary
- Critical: 0건, Major: 2건, Minor: 1건
""",
                encoding="utf-8",
            )

            gate_passed, _, quality = check_hard_quality_gate(jobs_dir, "impl")
            self.assertFalse(gate_passed)
            self.assertEqual(quality.major_count, 2)
            self.assertEqual(quality.critical_count, 0)

    def test_impl_pass_without_major_is_allowed(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            jobs_dir = Path(td) / "jobs" / "feature-a"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "review-implement.md").write_text(
                """# Implementation Review

## Result: PASS

## Review Summary
- Critical: 0건, Major: 0건, Minor: 3건
""",
                encoding="utf-8",
            )

            gate_passed, _, quality = check_hard_quality_gate(jobs_dir, "impl")
            self.assertTrue(gate_passed)
            self.assertEqual(quality.major_count, 0)

    def test_plan_result_is_parsed_from_content_not_filename(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            jobs_dir = Path(td) / "jobs" / "feature-a"
            jobs_dir.mkdir(parents=True)
            # review-checklist prefix라도 내용이 FAIL이면 FAIL로 판정되어야 한다.
            (jobs_dir / "review-checklist_01.md").write_text(
                "# Review Checklist\n\n## Result: FAIL\n",
                encoding="utf-8",
            )

            self.assertFalse(is_review_pass(jobs_dir, "plan"))

    def test_quality_parser_extracts_test_statuses(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            jobs_dir = Path(td) / "jobs" / "feature-a"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "review-implement.md").write_text(
                """## Result: PASS

Unit Test: PASS
UI Test: SKIPPED
Lint: FAIL
""",
                encoding="utf-8",
            )

            quality = evaluate_review_quality(jobs_dir, "impl")
            self.assertEqual(quality.unit_test_status, "PASS")
            self.assertEqual(quality.ui_test_status, "SKIPPED")
            self.assertEqual(quality.lint_status, "FAIL")


class PipelineHardGateIntegrationTests(unittest.TestCase):
    def test_impl_loop_retries_when_reviewer_passes_but_hard_gate_fails(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_root = root / "jobs"
            feature = "impl-hard-gate-retry"
            jobs_dir = jobs_root / feature
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "review-checklist.md").write_text(
                """# Review Checklist

## Result: PASS

## UI Test Requirement
- Required: NO
- Reason: Non-UI feature
- Trigger IDs: N/A
- XCUITest Paths: N/A
- Test Filter: N/A
""",
                encoding="utf-8",
            )

            implementor_calls = {"count": 0}
            reviewer_calls = {"count": 0}

            def fake_stage_implementor(_feature: str, _feedback: str | None = None) -> None:
                implementor_calls["count"] += 1

            def fake_stage_reviewer_impl(_feature: str) -> tuple[bool, str]:
                reviewer_calls["count"] += 1
                if reviewer_calls["count"] == 1:
                    major_count = 1
                else:
                    major_count = 0
                (jobs_dir / "review-implement.md").write_text(
                    (
                        "## Result: PASS\n\n"
                        "## Review Summary\n"
                        f"- Critical: 0건, Major: {major_count}건, Minor: 0건\n"
                    ),
                    encoding="utf-8",
                )
                return True, ""

            with mock.patch.object(cfg, "PROJECT_ROOT", root), mock.patch.object(
                cfg, "JOBS_DIR", jobs_root
            ), mock.patch.object(cfg, "MAX_REVIEW_LOOPS", 3), mock.patch.object(
                pipeline, "stage_implementor", side_effect=fake_stage_implementor
            ), mock.patch.object(
                pipeline, "stage_reviewer_impl", side_effect=fake_stage_reviewer_impl
            ):
                pipeline._run_impl_review_loop(feature)

            self.assertEqual(implementor_calls["count"], 2)


if __name__ == "__main__":
    unittest.main()
