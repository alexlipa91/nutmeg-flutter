#!/usr/bin/env python3
"""Run post-match tasks for a match directly (no Flask server needed).

Usage:
    python scripts/run_post_match.py <match_id> [--test]
    python scripts/run_post_match.py <match_id> --payout [--test] [--attempt N]
"""
import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import firebase_admin
from firebase_admin import firestore

firebase_admin.initialize_app()
db = firestore.client()

from src.secrets import load_secrets
load_secrets()

from src.blueprints.matches import _run_post_match_tasks, _create_organizer_payout

parser = argparse.ArgumentParser(description="Run post-match tasks")
parser.add_argument("match_id", help="Firestore match document ID")
parser.add_argument("--test", action="store_true", help="Use test collection")
parser.add_argument("--payout", action="store_true", help="Run payout only")
parser.add_argument("--attempt", type=int, default=1, help="Payout attempt number")
args = parser.parse_args()

if args.payout:
    print(f"Running payout for match {args.match_id} (attempt {args.attempt}, test={args.test})")
    result = _create_organizer_payout(db, args.match_id, args.test, attempt=args.attempt)
else:
    print(f"Running post-match tasks for match {args.match_id} (test={args.test})")
    result = _run_post_match_tasks(db, args.match_id, args.test)

print(result)
