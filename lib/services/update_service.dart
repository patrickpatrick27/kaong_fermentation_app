import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  // Replace this with your actual GitHub Releases API URL or your JSON endpoint
  // Example: 'https://api.github.com/repos/YOUR_USER/YOUR_REPO/releases/latest'
  final String _versionCheckUrl = 'YOUR_VERSION_CHECK_URL_HERE'; 

  /// Checks if a new version is available.
  /// Returns the Download URL if update is needed, otherwise null.
  Future<String?> checkForUpdate() async {
    try {
      // 1. Get Current App Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      
      debugPrint("Current Version: $currentVersion");

      // 2. Fetch Latest Version Info from your Server/GitHub
      // NOTE: You need to parse your specific JSON structure here.
      // This is a generic example assuming a simple JSON response.
      final dio = Dio();
      final response = await dio.get(_versionCheckUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        // Adjust these keys based on your actual API response
        String latestVersion = data['tag_name'] ?? data['version']; 
        String downloadUrl = data['assets'][0]['browser_download_url'] ?? data['url'];

        // Remove 'v' prefix if present (e.g., v1.0.1 -> 1.0.1)
        latestVersion = latestVersion.replaceAll('v', '');

        // 3. Compare Versions
        if (_isNewerVersion(latestVersion, currentVersion)) {
          debugPrint("Update Available: $latestVersion");
          return downloadUrl;
        }
      }
    } catch (e) {
      debugPrint("Error checking for updates: $e");
    }
    return null;
  }

  /// Downloads the APK and triggers the installation.
  Future<void> downloadUpdate(String url) async {
    try {
      debugPrint("Downloading update from: $url");
      
      // 1. Find a valid download location (Temp is safest for updates)
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/update.apk';

      // 2. Download the file
      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint("Download progress: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      debugPrint("Download finished. Path: $savePath");

      // 3. Install the Update
      // This uses OpenFilex which handles the FileProvider intent automatically
      final result = await OpenFilex.open(savePath);
      debugPrint("Install intent result: ${result.message}");

    } catch (e) {
      debugPrint("Download/Install failed: $e");
    }
  }

  /// Helper to compare version strings (e.g., "1.0.2" > "1.0.1")
  bool _isNewerVersion(String latest, String current) {
    List<int> l = latest.split('.').map(int.parse).toList();
    List<int> c = current.split('.').map(int.parse).toList();

    for (int i = 0; i < l.length; i++) {
      if (i >= c.length || l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }
}