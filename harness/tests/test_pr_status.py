import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.pr_status import fetch_feature_pr_states


class PrStatusTests(unittest.TestCase):
    def test_returns_empty_when_gh_missing(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            with mock.patch("harness.pr_status.shutil.which", return_value=None):
                states = fetch_feature_pr_states(root)
            self.assertEqual(states, {})

    def test_parses_open_closed_merged_states(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            payload = [
                {
                    "headRefName": "feature/open-item",
                    "mergedAt": None,
                    "number": 11,
                    "state": "OPEN",
                    "updatedAt": "2026-04-08T00:00:00Z",
                    "url": "https://example.com/pr/11",
                },
                {
                    "headRefName": "feature/closed-item",
                    "mergedAt": None,
                    "number": 12,
                    "state": "CLOSED",
                    "updatedAt": "2026-04-08T01:00:00Z",
                    "url": "https://example.com/pr/12",
                },
                {
                    "headRefName": "feature/merged-item",
                    "mergedAt": "2026-04-08T02:00:00Z",
                    "number": 13,
                    "state": "MERGED",
                    "updatedAt": "2026-04-08T02:00:00Z",
                    "url": "https://example.com/pr/13",
                },
                {
                    "headRefName": "bugfix/not-feature",
                    "mergedAt": None,
                    "number": 99,
                    "state": "OPEN",
                    "updatedAt": "2026-04-08T03:00:00Z",
                    "url": "https://example.com/pr/99",
                },
            ]

            proc = mock.Mock(returncode=0, stdout=json.dumps(payload), stderr="")
            with mock.patch("harness.pr_status.shutil.which", return_value="/usr/bin/gh"), mock.patch(
                "harness.pr_status.subprocess.run",
                return_value=proc,
            ):
                states = fetch_feature_pr_states(root)

            self.assertEqual(states["open-item"].state, "open")
            self.assertFalse(states["open-item"].is_terminal)
            self.assertEqual(states["closed-item"].state, "closed")
            self.assertTrue(states["closed-item"].is_terminal)
            self.assertEqual(states["merged-item"].state, "merged")
            self.assertTrue(states["merged-item"].is_terminal)
            self.assertNotIn("not-feature", states)

    def test_keeps_latest_pr_when_same_feature_has_multiple_entries(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            payload = [
                {
                    "headRefName": "feature/sample",
                    "mergedAt": None,
                    "number": 20,
                    "state": "OPEN",
                    "updatedAt": "2026-04-08T01:00:00Z",
                    "url": "https://example.com/pr/20",
                },
                {
                    "headRefName": "feature/sample",
                    "mergedAt": "2026-04-08T03:00:00Z",
                    "number": 21,
                    "state": "MERGED",
                    "updatedAt": "2026-04-08T03:00:00Z",
                    "url": "https://example.com/pr/21",
                },
            ]

            proc = mock.Mock(returncode=0, stdout=json.dumps(payload), stderr="")
            with mock.patch("harness.pr_status.shutil.which", return_value="/usr/bin/gh"), mock.patch(
                "harness.pr_status.subprocess.run",
                return_value=proc,
            ):
                states = fetch_feature_pr_states(root)

            self.assertIn("sample", states)
            self.assertEqual(states["sample"].number, 21)
            self.assertEqual(states["sample"].state, "merged")

    def test_ignores_non_feature_branches(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            payload = [
                {
                    "headRefName": "bugfix/sample",
                    "mergedAt": None,
                    "number": 20,
                    "state": "OPEN",
                    "updatedAt": "2026-04-08T01:00:00Z",
                    "url": "https://example.com/pr/20",
                },
            ]

            proc = mock.Mock(returncode=0, stdout=json.dumps(payload), stderr="")
            with mock.patch("harness.pr_status.shutil.which", return_value="/usr/bin/gh"), mock.patch(
                "harness.pr_status.subprocess.run",
                return_value=proc,
            ):
                states = fetch_feature_pr_states(root)

            self.assertEqual(states, {})


if __name__ == "__main__":
    unittest.main()
