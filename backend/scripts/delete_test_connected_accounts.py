"""Delete all test Stripe connected accounts.

Run from the backend directory:
    python3 scripts/delete_test_connected_accounts.py
"""
import stripe
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.secrets import Secrets, load_secrets

load_secrets()

stripe.api_key = Secrets.STRIPE_KEY_TEST

accounts = stripe.Account.list(limit=100)
count = 0

for account in accounts.auto_paging_iter():
    name = (account.business_profile or {}).get("name", "unnamed")
    print(f"Deleting {account.id} ({name})...")
    stripe.Account.delete(account.id)
    count += 1

print(f"\nDone. Deleted {count} test connected account(s).")
