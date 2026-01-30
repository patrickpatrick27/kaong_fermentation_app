import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  // ✅ Your Specific GitHub Details
  final String _gitHubUsername = 'patrickpatrick27';
  final String _gitHubRepo = 'kaong_fermentation_app';

  /// Checks if a new version is available.
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
      final response = await dio.get(
        url,
        options: Options(headers: {
          'User-Agent': 'KaongFermentationApp',
          'Accept': 'application/vnd.github.v3+json',
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // 4. Parse Version Tag
        String latestTag = data['tag_name'] ?? '0.0.0'; 
        String latestVersion = latestTag.replaceAll('v', '');
        debugPrint("☁️ GitHub Latest Version: $latestVersion");

        // 5. Compare Versions
        if (!_isNewerVersion(latestVersion, currentVersion)) {
          debugPrint("✅ App is already up to date.");
          return null;
        }

        // 6. Find the .apk Asset
        List assets = data['assets'];
        if (assets.isEmpty) return null;

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
      }
    } catch (e) {
      debugPrint("❌ Update Check Failed: $e");
    }
    return null;
  }

  /// Downloads the APK and triggers the installation.
  /// [onProgress] is a callback that receives a value between 0.0 and 1.0
  Future<void> downloadUpdate(String url, {Function(double)? onProgress}) async {
    try {
      debugPrint("⬇️ STARTING DOWNLOAD: $url");
      
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/kaong_update.apk';

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            // Calculate progress and send it back to UI
            double progress = received / total;
            onProgress(progress);
          }
        },
      );

      debugPrint("✅ Download Finished. Path: $savePath");

      debugPrint("📦 Attempting to open install intent...");
      final result = await OpenFilex.open(savePath);
      debugPrint("📦 Install Result: ${result.message}");

    } catch (e) {
      debugPrint("❌ Download/Install Failed: $e");
      throw e; // Rethrow so UI can show error state
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      List<int> l = latest.split('.').map(int.parse).toList();
      List<int> c = current.split('.').map(int.parse).toList();

      for (int i = 0; i < l.length; i++) {
        if (i >= c.length || l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
    } catch (e) {
      debugPrint("⚠️ Version Parsing Error: $e");
    }
    return false;
  }
}