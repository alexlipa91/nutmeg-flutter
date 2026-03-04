#!/usr/bin/env python3
"""Run release match money task directly (no Flask server needed).

Usage:
    python scripts/release_match_money.py <match_id> [--test]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.bootstrap import init
from src.blueprints.matches import _release_match_money


def main():
    parser = argparse.ArgumentParser(description="Release match money")
    parser.add_argument("match_id", help="Firestore match document ID")
    parser.add_argument("--test", action="store_true", help="Use test collection")
    args = parser.parse_args()

    db = init()

    print(f"Running release for match {args.match_id} (test={args.test})")
    result = _release_match_money(db, args.match_id, args.test)
    print(result)


if __name__ == "__main__":
    main()
