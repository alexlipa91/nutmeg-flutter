#!/usr/bin/env python3
"""
Move/merge user stats from one user ID to another.

Default mode is DRY RUN.

Usage:
  python scripts/move_user_stats.py <from_user_id> <to_user_id>
  python scripts/move_user_stats.py <from_user_id> <to_user_id> --write
  python scripts/move_user_stats.py <from_user_id> <to_user_id> --write --delete-source
"""
import argparse
import os
from typing import Any, Dict

import firebase_admin
from firebase_admin import credentials, firestore


TOP_LEVEL_NUMERIC_FIELDS = [
    "num_matches_joined",
]

TOP_LEVEL_COUNTER_MAP_FIELDS = [
    "played_with",
    "organizer_players",
]

TOP_LEVEL_DICT_UNION_FIELDS = [
    "potm_dates",
    "last_date_scores",
]


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _merge_counter_maps(
    source_map: Dict[str, Any] | None,
    target_map: Dict[str, Any] | None,
) -> Dict[str, int]:
    merged: Dict[str, int] = {}
    for key, value in (target_map or {}).items():
        merged[key] = int(value) if _is_number(value) else 0
    for key, value in (source_map or {}).items():
        if not _is_number(value):
            continue
        merged[key] = merged.get(key, 0) + int(value)
    return merged


def _merge_dict_union(
    source_map: Dict[str, Any] | None,
    target_map: Dict[str, Any] | None,
) -> Dict[str, Any]:
    merged = dict(target_map or {})
    for key, value in (source_map or {}).items():
        if key not in merged:
            merged[key] = value
    return merged


def _merge_scores(source_scores: Dict[str, Any], target_scores: Dict[str, Any]) -> Dict[str, Any]:
    source_games = source_scores.get("number_of_scored_games", 0)
    source_sum = source_scores.get("total_sum", 0)
    target_games = target_scores.get("number_of_scored_games", 0)
    target_sum = target_scores.get("total_sum", 0)

    return {
        "number_of_scored_games": int(target_games) + int(source_games),
        "total_sum": float(target_sum) + float(source_sum),
    }


def _merge_record(source_record: Dict[str, Any], target_record: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "num_win": int(target_record.get("num_win", 0)) + int(source_record.get("num_win", 0)),
        "num_draw": int(target_record.get("num_draw", 0)) + int(source_record.get("num_draw", 0)),
        "num_loss": int(target_record.get("num_loss", 0)) + int(source_record.get("num_loss", 0)),
    }


def _merge_joined_matches(
    source_doc_data: Dict[str, Any],
    target_doc_data: Dict[str, Any],
) -> Dict[str, Any]:
    source_joined = source_doc_data.get("joinedMatches", {}) or {}
    target_joined = target_doc_data.get("joinedMatches", {}) or {}
    merged = dict(target_joined)
    for match_id, joined_at in source_joined.items():
        if match_id not in merged:
            merged[match_id] = joined_at
    return {"joinedMatches": merged}


def _build_app(service_account_path: str | None) -> None:
    if firebase_admin._apps:
        return

    if service_account_path and os.path.exists(service_account_path):
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()


def move_user_stats(
    db: firestore.Client,
    source_user_id: str,
    target_user_id: str,
    write: bool,
    delete_source: bool,
) -> None:
    source_ref = db.collection("users").document(source_user_id)
    target_ref = db.collection("users").document(target_user_id)

    source_doc = source_ref.get()
    if not source_doc.exists:
        raise RuntimeError(f"Source user not found: {source_user_id}")
    target_doc = target_ref.get()
    if not target_doc.exists:
        raise RuntimeError(f"Target user not found: {target_user_id}")

    source_data = source_doc.to_dict() or {}
    target_data = target_doc.to_dict() or {}

    update_payload: Dict[str, Any] = {}

    for field in TOP_LEVEL_NUMERIC_FIELDS:
        source_value = source_data.get(field, 0)
        target_value = target_data.get(field, 0)
        if _is_number(source_value) or _is_number(target_value):
            update_payload[field] = int(target_value or 0) + int(source_value or 0)

    for field in TOP_LEVEL_COUNTER_MAP_FIELDS:
        merged = _merge_counter_maps(source_data.get(field), target_data.get(field))
        if merged:
            update_payload[field] = merged

    for field in TOP_LEVEL_DICT_UNION_FIELDS:
        merged = _merge_dict_union(source_data.get(field), target_data.get(field))
        if merged:
            update_payload[field] = merged

    if source_data.get("scores") or target_data.get("scores"):
        update_payload["scores"] = _merge_scores(
            source_data.get("scores", {}) or {},
            target_data.get("scores", {}) or {},
        )

    if source_data.get("record") or target_data.get("record"):
        update_payload["record"] = _merge_record(
            source_data.get("record", {}) or {},
            target_data.get("record", {}) or {},
        )

    source_stats_ref = source_ref.collection("stats").document("match_votes")
    target_stats_ref = target_ref.collection("stats").document("match_votes")
    source_stats_doc = source_stats_ref.get()
    target_stats_doc = target_stats_ref.get()

    source_stats_data = source_stats_doc.to_dict() or {}
    target_stats_data = target_stats_doc.to_dict() or {}
    merged_stats = _merge_joined_matches(source_stats_data, target_stats_data)

    source_stats_test_ref = source_ref.collection("stats_test").document("match_votes")
    target_stats_test_ref = target_ref.collection("stats_test").document("match_votes")
    source_stats_test_doc = source_stats_test_ref.get()
    target_stats_test_doc = target_stats_test_ref.get()

    source_stats_test_data = source_stats_test_doc.to_dict() or {}
    target_stats_test_data = target_stats_test_doc.to_dict() or {}
    merged_stats_test = _merge_joined_matches(source_stats_test_data, target_stats_test_data)

    print(f"Source: {source_user_id}")
    print(f"Target: {target_user_id}")
    print(f"Mode: {'WRITE' if write else 'DRY RUN'}")
    print()
    print("Top-level merged fields:")
    for key in sorted(update_payload.keys()):
        print(f"  - {key}")
    print(f"Joined matches (stats): {len(merged_stats.get('joinedMatches', {}))}")
    print(f"Joined matches (stats_test): {len(merged_stats_test.get('joinedMatches', {}))}")
    print()

    if not write:
        print("Dry run complete. Re-run with --write to apply changes.")
        return

    if update_payload:
        target_ref.update(update_payload)
    if merged_stats.get("joinedMatches"):
        target_stats_ref.set(merged_stats, merge=True)
    if merged_stats_test.get("joinedMatches"):
        target_stats_test_ref.set(merged_stats_test, merge=True)

    print("Target user updated.")

    if delete_source:
        source_cleanup: Dict[str, Any] = {}
        for field in TOP_LEVEL_NUMERIC_FIELDS:
            if field in source_data:
                source_cleanup[field] = 0
        for field in TOP_LEVEL_COUNTER_MAP_FIELDS + TOP_LEVEL_DICT_UNION_FIELDS:
            if field in source_data:
                source_cleanup[field] = {}
        if "scores" in source_data:
            source_cleanup["scores"] = {"number_of_scored_games": 0, "total_sum": 0}
        if "record" in source_data:
            source_cleanup["record"] = {"num_win": 0, "num_draw": 0, "num_loss": 0}

        if source_cleanup:
            source_ref.update(source_cleanup)
        if source_stats_doc.exists:
            source_stats_ref.delete()
        if source_stats_test_doc.exists:
            source_stats_test_ref.delete()
        print("Source stats cleared.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Move/merge user stats between user IDs")
    parser.add_argument("from_user_id", help="Source user ID")
    parser.add_argument("to_user_id", help="Target user ID")
    parser.add_argument("--write", action="store_true", help="Apply changes (default is dry-run)")
    parser.add_argument(
        "--delete-source",
        action="store_true",
        help="After moving, clear source stats fields/docs",
    )
    parser.add_argument(
        "--service-account",
        default=os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            "nutmeg-9099c-firebase-adminsdk.json",
        ),
        help="Service account JSON path (defaults to backend/nutmeg-9099c-firebase-adminsdk.json)",
    )
    args = parser.parse_args()

    if args.from_user_id == args.to_user_id:
        raise RuntimeError("from_user_id and to_user_id must be different")

    _build_app(args.service_account)
    db = firestore.client()

    move_user_stats(
        db=db,
        source_user_id=args.from_user_id,
        target_user_id=args.to_user_id,
        write=args.write,
        delete_source=args.delete_source,
    )


if __name__ == "__main__":
    main()
