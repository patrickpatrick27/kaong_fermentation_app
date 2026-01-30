import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  // ✅ 1. Your Specific GitHub Details
  final String _gitHubUsername = 'patrickpatrick27';
  final String _gitHubRepo = 'kaong_fermentation_app';

  /// Checks if a new version is available.
  /// Returns the Download URL if update is needed, otherwise null.
  Future<String?> checkForUpdate() async {
    try {
      debugPrint("🔍 UPDATE SERVICE: Checking for updates...");

      // 1. Get Current App Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      debugPrint("📱 Current Installed Version: $currentVersion");

      // 2. Construct the GitHub API URL
      final String url = 'https://api.github.com/repos/$_gitHubUsername/$_gitHubRepo/releases/latest';
      
      // 3. Fetch Release Info
      final dio = Dio();
      // ⚠️ GitHub API REQUIRES a User-Agent header, or it will block the request.
      final response = await dio.get(
        url,
        options: Options(headers: {
          'User-Agent': 'KaongFermentationApp',
          'Accept': 'application/vnd.github.v3+json',
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // 4. Parse Version Tag (e.g., "v1.0.2" -> "1.0.2")
        String latestTag = data['tag_name'] ?? '0.0.0'; 
        String latestVersion = latestTag.replaceAll('v', '');
        
        debugPrint("☁️ GitHub Latest Version: $latestVersion");

        // 5. Compare Versions
        if (!_isNewerVersion(latestVersion, currentVersion)) {
          debugPrint("✅ App is already up to date.");
          return null;
        }

        // 6. Find the .apk Asset
        // We cannot just grab [0] because GitHub often lists Source Code zips first.
        List assets = data['assets'];
        if (assets.isEmpty) {
          debugPrint("⚠️ Release found, but no assets attached.");
          return null;
        }

        var apkAsset = assets.firstWhere(
          (asset) => asset['name'].toString().toLowerCase().endsWith('.apk'),
          orElse: () => null,
        );

        if (apkAsset == null) {
          debugPrint("⚠️ No .apk file found in the latest release.");
          return null;
        }

        String downloadUrl = apkAsset['browser_download_url'];
        debugPrint("🚀 UPDATE FOUND! URL: $downloadUrl");
        return downloadUrl;

      } else {
        debugPrint("⚠️ GitHub API Error: ${response.statusCode} - ${response.statusMessage}");
      }
    } catch (e) {
      debugPrint("❌ Update Check Failed: $e");
    }
    return null;
  }

  /// Downloads the APK and triggers the installation.
  Future<void> downloadUpdate(String url) async {
    try {
      debugPrint("⬇️ STARTING DOWNLOAD: $url");
      
      // 1. Find a valid download location (Temp directory is safest for installs)
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/kaong_update.apk';

      // 2. Download the file
      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Log every 20% to avoid spamming the console
            if ((received / total * 100) % 20 < 1) {
              debugPrint("⬇️ Download Progress: ${(received / total * 100).toStringAsFixed(0)}%");
            }
          }
        },
      );

      debugPrint("✅ Download Finished. Path: $savePath");

      // 3. Install the Update
      debugPrint("📦 Attempting to open install intent...");
      final result = await OpenFilex.open(savePath);
      debugPrint("📦 Install Result: ${result.message}");

    } catch (e) {
      debugPrint("❌ Download/Install Failed: $e");
    }
  }

  /// Helper to compare version strings (e.g., "1.0.2" > "1.0.1")
  bool _isNewerVersion(String latest, String current) {
    try {
      List<int> l = latest.split('.').map(int.parse).toList();
      List<int> c = current.split('.').map(int.parse).toList();

      for (int i = 0; i < l.length; i++) {
        // If latest has more parts or a larger number
        if (i >= c.length || l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
    } catch (e) {
      debugPrint("⚠️ Version Parsing Error: $e");
    }
    return false;
  }
}