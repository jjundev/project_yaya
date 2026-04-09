from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

import harness.agent as agent
import harness.config as cfg
import harness.pipeline as pipeline
from harness.config import PipelineError


class RequirementFallbackTests(unittest.TestCase):
    def test_ensure_requirement_file_uses_existing_worktree_file(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source_root = root / "source"
            worktree_root = root / "worktree"
            source_req = source_root / "requirements" / "requirement_alpha.md"
            target_req = worktree_root / "requirements" / "requirement_alpha.md"

            source_req.parent.mkdir(parents=True)
            target_req.parent.mkdir(parents=True)
            source_req.write_text("source", encoding="utf-8")
            target_req.write_text("target", encoding="utf-8")

            with mock.patch.object(cfg, "PROJECT_ROOT", worktree_root), mock.patch.object(
                pipeline, "_source_project_root", return_value=source_root
            ):
                resolved = pipeline._ensure_requirement_file("alpha")

            self.assertEqual(resolved, target_req)
            self.assertEqual(target_req.read_text(encoding="utf-8"), "target")

    def test_ensure_requirement_file_copies_from_source_if_missing(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source_root = root / "source"
            worktree_root = root / "worktree"
            source_req = source_root / "requirements" / "requirement_beta.md"
            target_req = worktree_root / "requirements" / "requirement_beta.md"

            source_req.parent.mkdir(parents=True)
            source_req.write_text("copied from source", encoding="utf-8")

            with mock.patch.object(cfg, "PROJECT_ROOT", worktree_root), mock.patch.object(
                pipeline, "_source_project_root", return_value=source_root
            ):
                resolved = pipeline._ensure_requirement_file("beta")

            self.assertEqual(resolved, target_req)
            self.assertTrue(target_req.exists())
            self.assertEqual(target_req.read_text(encoding="utf-8"), "copied from source")

    def test_ensure_requirement_file_raises_when_missing_everywhere(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source_root = root / "source"
            worktree_root = root / "worktree"

            with mock.patch.object(cfg, "PROJECT_ROOT", worktree_root), mock.patch.object(
                pipeline, "_source_project_root", return_value=source_root
            ):
                with self.assertRaises(PipelineError):
                    pipeline._ensure_requirement_file("gamma")


class SkillFallbackTests(unittest.TestCase):
    def test_load_skill_prefers_worktree_skill(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            skills_dir = root / "skills"
            skill_file = skills_dir / "planner" / "SKILL.md"
            skill_file.parent.mkdir(parents=True)
            skill_file.write_text("primary skill", encoding="utf-8")

            fallback_dir = root / "fallback"
            fallback_file = fallback_dir / "planner" / "SKILL.md"
            fallback_file.parent.mkdir(parents=True)
            fallback_file.write_text("fallback skill", encoding="utf-8")

            with mock.patch.object(cfg, "SKILLS_DIR", skills_dir), mock.patch.object(
                agent, "_source_skills_dir", return_value=fallback_dir
            ):
                loaded = agent.load_skill("planner")

            self.assertEqual(loaded, "primary skill")

    def test_load_skill_falls_back_to_source_skill(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            skills_dir = root / "skills"
            fallback_dir = root / "fallback"
            fallback_file = fallback_dir / "planner" / "SKILL.md"
            fallback_file.parent.mkdir(parents=True)
            fallback_file.write_text("fallback skill", encoding="utf-8")

            with mock.patch.object(cfg, "SKILLS_DIR", skills_dir), mock.patch.object(
                agent, "_source_skills_dir", return_value=fallback_dir
            ):
                loaded = agent.load_skill("planner")

            self.assertEqual(loaded, "fallback skill")

    def test_load_skill_raises_when_missing(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            skills_dir = root / "skills"
            fallback_dir = root / "fallback"

            with mock.patch.object(cfg, "SKILLS_DIR", skills_dir), mock.patch.object(
                agent, "_source_skills_dir", return_value=fallback_dir
            ):
                with self.assertRaises(FileNotFoundError):
                    agent.load_skill("planner")


if __name__ == "__main__":
    unittest.main()
