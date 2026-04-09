#!/usr/bin/env python3
"""Backward-compatible wrapper for the package-based harness.

Usage examples:
    python harness.py <feature>
    python harness.py doctor
    python harness.py --web --port 8420

This wrapper delegates all behavior to `python -m harness` implementation.
"""

from harness.__main__ import main


if __name__ == "__main__":
    main()
