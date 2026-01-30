// File: lib/services/update_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:r_upgrade/r_upgrade.dart';

class UpdateService {
  // TODO: Replace these with your actual GitHub details
  static const String githubUser = "patrickpatrick27"; 
  static const String githubRepo = "kaong_app_fermentation"; 

  // Checks if a new release exists
  Future<void> checkForUpdates(Function(String) onUpdateAvailable) async {
    try {
      // 1. Get current installed version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Query GitHub API
      final url = Uri.parse('https://api.github.com/repos/$githubUser/$githubRepo/releases/latest');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // GitHub tags usually look like "v1.0.0", so we remove the 'v'
        String latestTag = data['tag_name'].toString().replaceAll('v', ''); 
        
        // Get the APK download URL from assets
        String? apkUrl;
        if (data['assets'] != null && data['assets'].isNotEmpty) {
           apkUrl = data['assets'][0]['browser_download_url'];
        }

        // 3. Compare versions
        if (latestTag != currentVersion && apkUrl != null) {
          onUpdateAvailable(apkUrl);
        }
      }
    } catch (e) {
      // Fail silently if no internet or API limit reached
      print("Update check failed: $e");
    }
  }

  // Triggers the download and install interface
  void downloadAndInstall(String url) async {
    await RUpgrade.upgrade(url, fileName: 'kaong_monitor_update.apk');
  }
}