"""
Quick script to simulate a Stripe account.updated webhook hitting your local backend.

Usage:
    python3 scripts/test_webhook_local.py <connected_account_id> <user_id>

Example:
    python3 scripts/test_webhook_local.py acct_1234567890 IwrZWBFb4LZl3Kto1V3oUKPnCni1
"""
import requests
import json
import sys
import time

BACKEND_URL = "http://localhost:8080"

if len(sys.argv) < 3:
    print("Usage: python3 scripts/test_webhook_local.py <connected_account_id> <user_id>")
    sys.exit(1)

account_id = sys.argv[1]
user_id = sys.argv[2]

# Simulate a Stripe account.updated event payload
event = {
    "id": "evt_test_{}".format(int(time.time())),
    "object": "event",
    "type": "account.updated",
    "livemode": False,
    "data": {
        "object": {
            "id": account_id,
            "object": "account",
            "charges_enabled": True,
            "metadata": {
                "userId": user_id,
            },
        }
    }
}

print("Sending fake account.updated event to {}".format(BACKEND_URL))
print("  account_id: {}".format(account_id))
print("  user_id:    {}".format(user_id))
print("  charges_enabled: True")
print()

# The real webhook validates STRIPE_SIGNATURE, so this will fail
# signature verification. To bypass that for testing, we'll call
# the endpoint directly without signature — but since the real
# handler requires it, let's skip the webhook and directly call
# the /account/status endpoint + simulate the Firestore update instead.

# --- Option A: Test /account/status endpoint (no signature needed) ---
print("=== Testing /stripe/account/status ===")
r = requests.get(
    "{}/stripe/account/status".format(BACKEND_URL),
    params={"user_id": user_id},
    headers={"X-Test-Mode": "true"},
)
print("Status: {}".format(r.status_code))
print("Response: {}".format(json.dumps(r.json(), indent=2)))
print()

# --- Option B: Try the webhook (will likely fail signature check) ---
print("=== Testing /stripe/connect_account_updated_webhook ===")
print("(Expected to fail signature verification — that's OK)")
try:
    r = requests.post(
        "{}/stripe/connect_account_updated_webhook".format(BACKEND_URL),
        json=event,
        headers={
            "Content-Type": "application/json",
            "STRIPE_SIGNATURE": "t=0,v1=fake",
            "X-Test-Mode": "true",
        },
    )
    print("Status: {}".format(r.status_code))
    print("Response: {}".format(r.text[:500]))
except Exception as e:
    print("Error: {}".format(e))

print()
print("Done. Check your backend logs for output.")
