#!/bin/bash

# 1. Extract Version from pubspec.yaml
VERSION=$(grep 'version:' pubspec.yaml | cut -d ' ' -f 2 | cut -d '+' -f 1)
TAG="v$VERSION"

echo "🚀 Starting Release Process for Version: $TAG"

# 2. Safety Check: Stop if there are uncommitted changes
if [[ `git status --porcelain` ]]; then
  echo "❌ Error: You have uncommitted changes."
  echo "👉 Please commit your changes in Source Control first."
  exit 1
fi

# 3. Push Code to GitHub (Ensures remote has latest code)
echo "☁️  Pushing code to GitHub..."
git push origin HEAD

# 4. Create Git Tag & Push Tag
# (We force it just in case you already tagged it locally)
echo "🏷  Tagging version $TAG..."
git tag -f "$TAG"
git push origin "$TAG" -f

# 5. Build the Release APK
echo "🛠  Building Release APK... (This takes about a minute)"
flutter build apk --release

# 6. Prepare the file
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
NEW_NAME="build/app/outputs/flutter-apk/Kaong_Monitor_$TAG.apk"
mv "$APK_PATH" "$NEW_NAME"

# 7. Create GitHub Release with the APK
echo "📦 Uploading Release to GitHub..."
gh release create "$TAG" "$NEW_NAME" \
    --title "Version $VERSION" \
    --generate-notes

echo "✅ DONE! Version $TAG is live and downloadable."