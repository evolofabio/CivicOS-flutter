#!/bin/bash
# Deploy Landing Page su Firebase Hosting (target: landing)
set -e

echo "=== Deploy Landing Page su Firebase Hosting ==="
firebase deploy --only hosting:landing

echo "✓ Landing Page pubblicata!"
echo "  URL: https://civicos-landing.web.app"
