#!/usr/bin/env python3
"""
Script to fill a match with test users until it's full.

Usage:
    cd app-engine
    python scripts/fill_match.py <match_id> [--test]
"""
import sys
import os
import argparse

# Add parent directory to path so we can import from src
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import firebase_admin
from firebase_admin import firestore
from flask import Flask

# Initialize Firebase
firebase_admin.initialize_app()

app = Flask("fill_match")
app.db_client = firestore.client()

# Import after setting up app context
from src.blueprints.matches import add_user_to_match


def main():
    parser = argparse.ArgumentParser(description="Fill a match with test users")
    parser.add_argument("match_id", help="The match ID to fill")
    parser.add_argument("--test", action="store_true", help="Use matches_test collection")
    args = parser.parse_args()

    match_id = args.match_id
    collection = "matches_test" if args.test else "matches"

    test_user_ids = [f"test_{i}" for i in range(10)]
    
    with app.app_context():
        match_ref = app.db_client.collection(collection).document(match_id)
        match_data = match_ref.get().to_dict()
        
        if match_data is None:
            print(f"Error: match {match_id} not found in {collection}")
            sys.exit(1)
        
        max_players = match_data.get("maxPlayers", 0)
        going = match_data.get("going", {})
        current_count = len(going)
        
        print(f"\n=== Filling match {match_id} in {collection} ({current_count}/{max_players} players) ===\n")
        
        if current_count >= max_players:
            print("Match is already full!")
        else:
            for user_id in test_user_ids:
                match_data = match_ref.get().to_dict()
                going = match_data.get("going", {})
                
                if len(going) >= max_players:
                    print("Match is now full!")
                    break
                
                if user_id in going:
                    print(f"  Skipping {user_id} (already in match)")
                    continue
                
                print(f"  Adding {user_id}...")
                add_user_to_match(match_id, user_id, is_test=args.test)
        
        match_data = match_ref.get().to_dict()
        going = match_data.get("going", {})
        print(f"\n=== Match now has {len(going)}/{max_players} players ===")
        for uid in going:
            user_doc = app.db_client.collection("users").document(uid).get()
            user_name = user_doc.to_dict().get("name", "Unknown") if user_doc.exists else "Unknown"
            print(f"  - {uid}: {user_name}")


if __name__ == "__main__":
    main()
