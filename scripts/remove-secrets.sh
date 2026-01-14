#!/bin/bash

# Script to remove secrets from Git history
# ⚠️ WARNING: This will rewrite Git history!
# ⚠️ All team members will need to re-clone the repository

echo "🔒 Hallify - Secret Removal Script"
echo "=================================="
echo ""
echo "⚠️  WARNING: This will rewrite Git history!"
echo "⚠️  Backup your repository before proceeding!"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "📦 Installing BFG Repo-Cleaner..."
if ! command -v bfg &> /dev/null; then
    echo "Please install BFG Repo-Cleaner first:"
    echo "  - macOS: brew install bfg"
    echo "  - Linux: Download from https://rtyley.github.io/bfg-repo-cleaner/"
    echo "  - Windows: Download JAR from https://rtyley.github.io/bfg-repo-cleaner/"
    exit 1
fi

echo ""
echo "🧹 Removing sensitive files from history..."
bfg --delete-files firebase_options.dart
bfg --delete-files google-services.json
bfg --delete-files GoogleService-Info.plist
bfg --delete-files .env

echo ""
echo "🔄 Cleaning up Git repository..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "✅ Done! Now you need to:"
echo "  1. Rotate all exposed API keys immediately"
echo "  2. Force push: git push --force --all"
echo "  3. Notify team members to re-clone"
echo ""
echo "🔑 Don't forget to rotate these keys:"
echo "  - Firebase API keys"
echo "  - Cloudinary credentials"
echo "  - Google Maps API keys"
echo ""
