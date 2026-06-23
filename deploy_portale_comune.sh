#!/bin/bash
# Deploy Portale Comune su Firebase Hosting (target: portale)
set -e

echo "=== Deploy Portale Comune su Firebase Hosting ==="
firebase deploy --only hosting:portale

echo "✓ Portale Comune pubblicato!"
echo "  Configura il target su Firebase: firebase target:apply hosting portale <site-id>"