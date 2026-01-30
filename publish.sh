#!/bin/bash

# 1. Extract Version from pubspec.yaml
VERSION=$(grep 'version:' pubspec.yaml | cut -d ' ' -f 2 | cut -d '+' -f 1)
TAG="v$VERSION"

echo "🚀 Preparing Release for Version: $TAG"

# 2. Check if this tag already exists on GitHub to prevent errors
if gh release view "$TAG" > /dev/null 2>&1; then
    echo "❌ Error: Release $TAG already exists on GitHub!"
    echo "👉 Update the version in pubspec.yaml first."
    exit 1
fi

# 3. Build the Release APK (Hides confusing logs, shows progress)
echo "🛠  Building APK... (This may take a minute)"
flutter build apk --release

# 4. Rename the file to include the version
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
NEW_NAME="build/app/outputs/flutter-apk/Kaong_Monitor_$TAG.apk"
mv "$APK_PATH" "$NEW_NAME"

# 5. Create Git Tag & Release on GitHub
echo "📦 Uploading to GitHub Releases..."


# Create the tag locally and push it (so your code history is synced)
git tag "$TAG"
git push origin "$TAG"

# Create the release and attach the APK
gh release create "$TAG" "$NEW_NAME" \
    --title "Version $VERSION" \
    --generate-notes

echo "✅ Success! Update $TAG is live."