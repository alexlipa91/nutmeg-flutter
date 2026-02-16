#!/usr/bin/env python3
"""Generate a Firebase custom auth token for debugging.

Usage:
    python scripts/generate_auth_token.py <user_id>

The token is valid for 1 hour and can be used with signInWithCustomToken().
"""
import sys
import os

import firebase_admin
from firebase_admin import credentials, auth


def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/generate_auth_token.py <user_id>")
        sys.exit(1)

    user_id = sys.argv[1]

    sa_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "nutmeg-9099c-firebase-adminsdk.json")
    cred = credentials.Certificate(sa_path)
    firebase_admin.initialize_app(cred)

    custom_token = auth.create_custom_token(user_id)
    token_str = custom_token.decode("utf-8") if isinstance(custom_token, bytes) else custom_token

    print(token_str)


if __name__ == "__main__":
    main()
