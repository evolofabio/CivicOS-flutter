#!/bin/bash
# Deploy Portale Admin su Firebase Hosting (target: admin)
set -e

echo "=== Deploy Portale Admin su Firebase Hosting ==="
firebase deploy --only hosting:admin

echo "✓ Portale Admin pubblicato!"
echo "  Configura il target su Firebase: firebase target:apply hosting admin <site-id>"