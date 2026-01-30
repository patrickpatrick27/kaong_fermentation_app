# 🍷 Kaong Wine Fermentation Monitoring App

A mobile application for the **Automated Kaong Wine Fermentation System Design Project**. This app allows users to monitor fermentation machines in real-time and receives automatic over-the-air (OTA) updates via GitHub Releases.

## ✨ Features

* **Real-time Monitoring:** Connects to Firebase Realtime Database to display live machine status.
* **Secure Access:** Verifies Machine IDs (e.g., `machine_001`) before granting access.
* **Auto-Update System:** Automatically checks GitHub Releases for new APK versions and handles the download/installation process in-app.
* **Modern UI:** Built with a clean, glassmorphism-inspired design using Google Fonts and custom charts.

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Backend:** Firebase Realtime Database
* **Update System:** Dio, OpenFilex, Package Info Plus
* **UI Libraries:** `fl_chart`, `glassmorphism`, `percent_indicator`, `google_fonts`

## 🚀 Installation & Setup

### 1. Prerequisites

* Flutter SDK (3.0.0 or higher)
* Java/JDK 17 (for Android builds)
* A Firebase Project

### 2. Clone the Repository

```bash
git clone https://github.com/patrickpatrick27/kaong_fermentation_app.git
cd kaong_fermentation_app
flutter pub get
```

### 3. Firebase Configuration

1.  Download your `google-services.json` from the Firebase Console.
2.  Place it in: `android/app/google-services.json`.

### 4. Signing Configuration (Crucial for Updates)

To make the auto-updater work, the app must be signed with a release key.

1.  Create a `key.properties` file in the `android/` folder:
    ```properties
    storePassword=YOUR_STORE_PASSWORD
    keyPassword=YOUR_KEY_PASSWORD
    keyAlias=upload
    storeFile=../app/upload-keystore.jks
    ```
2.  Ensure your `upload-keystore.jks` is placed in `android/app/`.

## 📦 Building for Release

The auto-update feature **only works** when the app is built in release mode and signed properly.

```bash
flutter build apk --release
```

The output file will be at: `build/app/outputs/flutter-apk/app-release.apk`

## 🔄 How the Auto-Update Works

The app uses a custom `UpdateService` to keep itself up to date without the Play Store.

1.  **Check:** On startup, the app queries the GitHub Releases API for the latest tag.
2.  **Compare:** It checks if the remote version (e.g., `1.0.2`) is higher than the current local version (e.g., `1.0.1`).
3.  **Prompt:** If an update is found, a dialog appears.
4.  **Install:** The app downloads the specific `.apk` asset and triggers the Android system installer.

### To push a new update:

1.  Bump the version in `pubspec.yaml` (e.g., `version: 1.0.1+2`).
2.  Build the release APK: `flutter build apk --release`.
3.  Create a new **Release** on GitHub.
4.  **Crucial:** Upload the `app-release.apk` as an asset to that release.

## 🤝 Contributing

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**Developed for the Kaong Wine Fermentation Project**
