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
from harness.ui_test_gate import validate_impl_ui_test_gate, validate_plan_ui_test_gate


class UITestGateParserTests(unittest.TestCase):
    def test_required_yes_with_xcuitest_path_and_step_passes(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_dir = root / "jobs" / "feature-a"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "implement-plan.md").write_text(
                _plan_markdown_required_yes_xcui(),
                encoding="utf-8",
            )

            passed, feedback = validate_plan_ui_test_gate(root, jobs_dir)
            self.assertTrue(passed)
            self.assertEqual(feedback, "")

    def test_required_yes_missing_ui_test_path_fails(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_dir = root / "jobs" / "feature-a"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "implement-plan.md").write_text(
                _plan_markdown_missing_xcui_path(),
                encoding="utf-8",
            )

            passed, feedback = validate_plan_ui_test_gate(root, jobs_dir)
            self.assertFalse(passed)
            self.assertIn("UI test path", feedback)

    def test_required_no_with_reason_passes(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_dir = root / "jobs" / "feature-b"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "implement-plan.md").write_text(
                _plan_markdown_required_no(),
                encoding="utf-8",
            )

            passed, feedback = validate_plan_ui_test_gate(root, jobs_dir)
            self.assertTrue(passed)
            self.assertEqual(feedback, "")

    def test_missing_ui_test_requirement_section_fails(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_dir = root / "jobs" / "feature-c"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "implement-plan.md").write_text(
                "# Implementation Plan\n\n## Affected Files\n- 없음\n",
                encoding="utf-8",
            )

            passed, feedback = validate_plan_ui_test_gate(root, jobs_dir)
            self.assertFalse(passed)
            self.assertIn("Missing required section", feedback)

    def test_legacy_androidtest_paths_key_is_supported(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_dir = root / "jobs" / "feature-legacy"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "implement-plan.md").write_text(
                _plan_markdown_required_yes_legacy_android_key(),
                encoding="utf-8",
            )

            passed, feedback = validate_plan_ui_test_gate(root, jobs_dir)
            self.assertTrue(passed)
            self.assertEqual(feedback, "")


class UITestGatePipelineIntegrationTests(unittest.TestCase):
    def test_plan_loop_retries_when_reviewer_passes_but_gate_fails(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_root = root / "jobs"
            feature = "plan-retry-feature"
            jobs_dir = jobs_root / feature
            jobs_dir.mkdir(parents=True)

            planner_calls = {"count": 0}

            def fake_stage_planner(_feature: str, _feedback: str | None = None) -> None:
                planner_calls["count"] += 1
                content = (
                    _plan_markdown_missing_xcui_path()
                    if planner_calls["count"] == 1
                    else _plan_markdown_required_yes_xcui()
                )
                (jobs_dir / "implement-plan.md").write_text(content, encoding="utf-8")

            with mock.patch.object(cfg, "PROJECT_ROOT", root), mock.patch.object(
                cfg, "JOBS_DIR", jobs_root
            ), mock.patch.object(cfg, "MAX_REVIEW_LOOPS", 3), mock.patch.object(
                pipeline, "stage_planner", side_effect=fake_stage_planner
            ), mock.patch.object(
                pipeline, "stage_reviewer_plan", return_value=(True, "")
            ), mock.patch.object(
                pipeline, "check_hard_quality_gate", return_value=(True, "", object())
            ):
                pipeline._run_plan_review_loop(feature)

            self.assertEqual(planner_calls["count"], 2)

    def test_impl_loop_retries_when_gate_fails_after_reviewer_pass(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_root = root / "jobs"
            feature = "impl-retry-feature"
            jobs_dir = jobs_root / feature
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "review-checklist.md").write_text(
                _review_checklist_required_yes_xcui(),
                encoding="utf-8",
            )

            implementor_calls = {"count": 0}

            def fake_stage_implementor(_feature: str, _feedback: str | None = None) -> None:
                implementor_calls["count"] += 1
                test_file = root / "ios" / "Yaya" / "YayaUITests" / "SampleFlowUITests.swift"
                if implementor_calls["count"] == 1:
                    if test_file.exists():
                        test_file.unlink()
                    return

                test_file.parent.mkdir(parents=True, exist_ok=True)
                test_file.write_text("final class SampleFlowUITests {}\n", encoding="utf-8")

            with mock.patch.object(cfg, "PROJECT_ROOT", root), mock.patch.object(
                cfg, "JOBS_DIR", jobs_root
            ), mock.patch.object(cfg, "MAX_REVIEW_LOOPS", 3), mock.patch.object(
                pipeline, "stage_implementor", side_effect=fake_stage_implementor
            ), mock.patch.object(
                pipeline, "stage_reviewer_impl", return_value=(True, "")
            ), mock.patch.object(
                pipeline, "check_hard_quality_gate", return_value=(True, "", object())
            ):
                pipeline._run_impl_review_loop(feature)

            self.assertEqual(implementor_calls["count"], 2)

    def test_non_ui_required_no_does_not_force_ui_test_files(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_root = root / "jobs"
            feature = "impl-non-ui-feature"
            jobs_dir = jobs_root / feature
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "review-checklist.md").write_text(
                _review_checklist_required_no(),
                encoding="utf-8",
            )

            with mock.patch.object(cfg, "PROJECT_ROOT", root), mock.patch.object(
                cfg, "JOBS_DIR", jobs_root
            ), mock.patch.object(cfg, "MAX_REVIEW_LOOPS", 2), mock.patch.object(
                pipeline, "stage_implementor", return_value=None
            ) as implementor_mock, mock.patch.object(
                pipeline, "stage_reviewer_impl", return_value=(True, "")
            ), mock.patch.object(
                pipeline, "check_hard_quality_gate", return_value=(True, "", object())
            ):
                pipeline._run_impl_review_loop(feature)

            implementor_mock.assert_called_once()

    def test_impl_validator_fails_when_required_yes_path_missing(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            jobs_dir = root / "jobs" / "feature-d"
            jobs_dir.mkdir(parents=True)
            (jobs_dir / "review-checklist.md").write_text(
                _review_checklist_required_yes_xcui(),
                encoding="utf-8",
            )

            passed, feedback = validate_impl_ui_test_gate(root, jobs_dir)
            self.assertFalse(passed)
            self.assertIn("does not exist", feedback)


def _plan_markdown_required_yes_xcui() -> str:
    return """# Implementation Plan: Sample

## Affected Files
### Modified
| File | Risk Level | Changes |
|---|---|---|
| `ios/Yaya/Yaya/Views/SampleView.swift` | Medium | UI 업데이트 |

### Created
| File | Layer | Purpose |
|---|---|---|
| `ios/Yaya/YayaUITests/SampleFlowUITests.swift` | Test | XCUITest 시나리오 |

## Implementation Steps
### Step 1: UI 코드 수정
- **대상 파일**: `ios/Yaya/Yaya/Views/SampleView.swift`

### Step 2: XCUITest 추가
- **대상 파일**: `ios/Yaya/YayaUITests/SampleFlowUITests.swift`

## UI Test Requirement
- Required: YES
- Reason: 사용자 상호작용 UI 회귀를 자동 검증해야 함
- Trigger IDs: FR-12, LC-2
- XCUITest Paths: ios/Yaya/YayaUITests/SampleFlowUITests.swift
- Test Filter: YayaUITests/SampleFlowUITests
"""


def _plan_markdown_required_yes_legacy_android_key() -> str:
    return """# Implementation Plan: Legacy Compatibility Sample

## Affected Files
### Created
| File | Layer | Purpose |
|---|---|---|
| `app/src/androidTest/java/com/example/SampleUiTest.kt` | Test | Legacy key compatibility |

## Implementation Steps
### Step 1: Legacy path entry
- **대상 파일**: `app/src/androidTest/java/com/example/SampleUiTest.kt`

## UI Test Requirement
- Required: YES
- Reason: 레거시 호환 검증
- Trigger IDs: FR-1
- AndroidTest Paths: app/src/androidTest/java/com/example/SampleUiTest.kt
- Test Filter: com.example.SampleUiTest
"""


def _plan_markdown_missing_xcui_path() -> str:
    return """# Implementation Plan: Sample

## Affected Files
### Modified
| File | Risk Level | Changes |
|---|---|---|
| `ios/Yaya/Yaya/Views/SampleView.swift` | Medium | UI 업데이트 |

## Implementation Steps
### Step 1: UI 코드 수정
- **대상 파일**: `ios/Yaya/Yaya/Views/SampleView.swift`

## UI Test Requirement
- Required: YES
- Reason: 사용자 상호작용 UI 회귀를 자동 검증해야 함
- Trigger IDs: FR-12
- XCUITest Paths: ios/Yaya/YayaUITests/SampleFlowUITests.swift
- Test Filter: YayaUITests/SampleFlowUITests
"""


def _plan_markdown_required_no() -> str:
    return """# Implementation Plan: Sample Non UI

## Affected Files
### Modified
| File | Risk Level | Changes |
|---|---|---|
| `ios/Yaya/Yaya/Models/SampleModel.swift` | Low | 순수 도메인 로직 변경 |

## UI Test Requirement
- Required: NO
- Reason: UI 레이어 변경이 없고 도메인 로직만 수정됨
- Trigger IDs: N/A
- XCUITest Paths: N/A
- Test Filter: N/A
"""


def _review_checklist_required_yes_xcui() -> str:
    return """# Review Checklist: Sample

## Result: PASS

## UI Test Requirement
- Required: YES
- Reason: 화면 전환과 입력 상호작용 검증 필요
- Trigger IDs: FR-8, LC-1
- XCUITest Paths: ios/Yaya/YayaUITests/SampleFlowUITests.swift
- Test Filter: YayaUITests/SampleFlowUITests
"""


def _review_checklist_required_no() -> str:
    return """# Review Checklist: Sample

## Result: PASS

## UI Test Requirement
- Required: NO
- Reason: UI 변경 없음
- Trigger IDs: N/A
- XCUITest Paths: N/A
- Test Filter: N/A
"""


if __name__ == "__main__":
    unittest.main()
