#!/usr/bin/env bash
# Start the backend locally.
#
# Usage:
#   cd backend && ./scripts/start_local.sh
#
# For Stripe webhook forwarding, run this in a separate terminal BEFORE starting:
#   stripe listen \
#     --forward-to http://localhost:8080/stripe/checkout_webhook \
#     --forward-connect-to http://localhost:8080/stripe/connect_account_updated_webhook
# Then copy the whsec_... secret it prints and export before running this script:
#   export STRIPE_CHECKOUT_WEBHOOK=whsec_...

PORT=8080

if [[ -z "${STRIPE_CHECKOUT_WEBHOOK:-}" ]]; then
  echo ""
  echo "TIP: To receive Stripe webhooks locally, run in another terminal:"
  echo "  stripe listen \\"
  echo "    --forward-to http://localhost:${PORT}/stripe/checkout_webhook \\"
  echo "    --forward-connect-to http://localhost:${PORT}/stripe/connect_account_updated_webhook"
  echo ""
  echo "Then export the signing secret it prints:"
  echo "  export STRIPE_CHECKOUT_WEBHOOK=whsec_..."
  echo ""
  echo "Starting backend without webhook support..."
  echo ""
fi

python3 main.py
