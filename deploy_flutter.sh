#!/bin/bash
# Deploy Flutter Web App su Firebase Hosting (target: app)
set -e

echo "=== Build Flutter Web (release) ==="
flutter build web --release

echo "=== Deploy su Firebase Hosting (target: app) ==="
firebase deploy --only hosting:app

echo "✓ App Flutter pubblicata!"
echo "  URL: https://civicos-bb9f7.web.app  (oppure il tuo dominio custom)"