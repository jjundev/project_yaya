from __future__ import annotations

import unittest

from harness.web.runner import PipelineRunner, PipelineStatus


class RunnerStateParserTests(unittest.TestCase):
    def test_stage_header_updates_current_stage_and_marks_active(self) -> None:
        runner = PipelineRunner()
        runner.status = PipelineStatus.RUNNING

        runner._parse_line("  [PLANNER] attempt 1/3  [claude-opus-4-6]")

        self.assertEqual(runner.current_stage, "planner")
        self.assertEqual(runner.gan_phase, "plan")
        self.assertEqual(runner.gan_iteration, 1)
        stage = next(s for s in runner.stages if s.name == "planner")
        self.assertEqual(stage.status, "active")

    def test_pass_line_marks_current_stage_passed(self) -> None:
        runner = PipelineRunner()
        runner.status = PipelineStatus.RUNNING
        runner._parse_line("  [IMPLEMENTOR] attempt 1/3  [claude-opus-4-6]")

        runner._parse_line("  → PASS")

        stage = next(s for s in runner.stages if s.name == "implementor")
        self.assertEqual(stage.status, "passed")

    def test_fail_line_marks_current_stage_failed(self) -> None:
        runner = PipelineRunner()
        runner.status = PipelineStatus.RUNNING
        runner._parse_line("  [REVIEWER IMPL] attempt 1/3  [claude-sonnet-4-6]")

        runner._parse_line("  → FAIL (attempt 1/3)")

        stage = next(s for s in runner.stages if s.name == "reviewer_impl")
        self.assertEqual(stage.status, "failed")

    def test_complete_line_sets_completed_status(self) -> None:
        runner = PipelineRunner()
        runner.status = PipelineStatus.RUNNING
        runner._parse_line("  [REPORTER]  [claude-sonnet-4-6]")

        runner._parse_line("Pipeline complete.")

        self.assertEqual(runner.status, PipelineStatus.COMPLETED)


if __name__ == "__main__":
    unittest.main()
