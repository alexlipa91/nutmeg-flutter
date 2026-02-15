#!/usr/bin/env bash
# Start the backend locally.
#
# Usage:
#   cd backend && ./scripts/start_local.sh
#
# For Stripe webhook forwarding, run this in a separate terminal BEFORE starting:
#   stripe listen --forward-to http://localhost:8080
# Then copy the whsec_... secret it prints and export before running this script:
#   export STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET_TEST=whsec_...
#   export STRIPE_CHECKOUT_WEBHOOK_SECRET_TEST=whsec_...

PORT=8080

if [[ -z "${STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET_TEST:-}" ]]; then
  echo ""
  echo "TIP: To receive Stripe webhooks locally, run in another terminal:"
  echo "  stripe listen --forward-to http://localhost:${PORT}"
  echo ""
  echo "Then export the signing secret it prints:"
  echo "  export STRIPE_CONNECT_UPDATED_WEBHOOK_SECRET_TEST=whsec_..."
  echo "  export STRIPE_CHECKOUT_WEBHOOK_SECRET_TEST=whsec_..."
  echo ""
  echo "Starting backend without webhook support..."
  echo ""
fi

python3 main.py
