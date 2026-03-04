#!/usr/bin/env python3
"""Run post-match or release tasks for a match directly (no Flask server needed).

Usage:
    python scripts/run_post_match.py <match_id> [--test]
    python scripts/run_post_match.py <match_id> --release [--test]
"""
import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.bootstrap import init
db = init()

from src.blueprints.matches import _run_post_match_tasks, _release_match_money

parser = argparse.ArgumentParser(description="Run post-match tasks")
parser.add_argument("match_id", help="Firestore match document ID")
parser.add_argument("--test", action="store_true", help="Use test collection")
parser.add_argument("--release", action="store_true", help="Run release money only")
args = parser.parse_args()

if args.release:
    print(f"Running release for match {args.match_id} (test={args.test})")
    result = _release_match_money(db, args.match_id, args.test)
else:
    print(f"Running post-match tasks for match {args.match_id} (test={args.test})")
    result = _run_post_match_tasks(db, args.match_id, args.test)

print(result)
