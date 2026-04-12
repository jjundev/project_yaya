import tempfile
import unittest
from pathlib import Path
from unittest import mock

import harness.config as cfg
import harness.worktree as worktree
from harness.config import PipelineError


class WorktreeSafeModeTests(unittest.TestCase):
    def test_resolve_base_ref_local_head_uses_local_branch(self) -> None:
        root = Path("/tmp/repo")
        with mock.patch.object(worktree, "_branch_exists", return_value=True):
            base_ref = worktree._resolve_base_ref(root, "local_head")
        self.assertEqual(base_ref, cfg.BASE_BRANCH)

    def test_resolve_base_ref_local_head_fails_when_branch_missing(self) -> None:
        root = Path("/tmp/repo")
        with mock.patch.object(worktree, "_branch_exists", return_value=False):
            with self.assertRaises(PipelineError):
                worktree._resolve_base_ref(root, "local_head")

    def test_resolve_base_ref_origin_fetches_remote(self) -> None:
        root = Path("/tmp/repo")
        with mock.patch.object(worktree, "_git", return_value="") as git_mock:
            base_ref = worktree._resolve_base_ref(root, "origin")
        git_mock.assert_called_once_with("fetch", cfg.REMOTE, cfg.BASE_BRANCH, cwd=root)
        self.assertEqual(base_ref, f"{cfg.REMOTE}/{cfg.BASE_BRANCH}")

    def test_create_worktree_existing_branch_creates_backup_before_reset(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            wt = root / ".claude" / "worktrees" / "sample"
            branch = "feature/sample"

            with mock.patch.object(worktree, "repo_root", return_value=root), mock.patch.object(
                worktree, "worktree_path", return_value=wt
            ), mock.patch.object(
                worktree, "branch_name", return_value=branch
            ), mock.patch.object(
                worktree, "_resolve_base_ref", return_value=cfg.BASE_BRANCH
            ), mock.patch.object(
                worktree, "_branch_exists", return_value=True
            ), mock.patch.object(
                worktree, "_create_backup_branch", return_value=f"{branch}-backup"
            ) as backup_mock, mock.patch.object(worktree, "_git", return_value="") as git_mock:
                created = worktree.create_worktree("sample", source="local_head")

            self.assertEqual(created, wt)
            backup_mock.assert_called_once_with(root, branch)
            git_mock.assert_any_call("worktree", "add", str(wt), branch, cwd=root)
            git_mock.assert_any_call("reset", "--hard", cfg.BASE_BRANCH, cwd=wt)


if __name__ == "__main__":
    unittest.main()
