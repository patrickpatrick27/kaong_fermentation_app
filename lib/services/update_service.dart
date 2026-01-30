import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app_installer/flutter_app_installer.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  // Your GitHub details
  static const String githubUser = "patrickpatrick27"; 
  static const String githubRepo = "kaong_fermentation_app"; 

  /// 1. Check GitHub for a new version
  Future<void> checkForUpdates(Function(String) onUpdateAvailable) async {
    try {
      // Get current installed version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // Query GitHub API
      final url = Uri.parse('https://api.github.com/repos/$githubUser/$githubRepo/releases/latest');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // GitHub tags usually look like "v1.0.0", so we remove the 'v'
        String latestTag = data['tag_name'].toString().replaceAll('v', ''); 
        
        // Find the APK download URL in the assets list
        String? apkUrl;
        if (data['assets'] != null) {
          for (var asset in data['assets']) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'];
              break;
            }
          }
        }

        // Compare versions (Simple string check)
        // If the tag on GitHub is different from the installed version, prompt update
        if (latestTag != currentVersion && apkUrl != null) {
          onUpdateAvailable(apkUrl);
        }
      }
    } catch (e) {
      print("Update check failed: $e");
    }
  }

  /// 2. Download APK & Install
  Future<void> downloadAndInstall(String url) async {
    // Request storage & install permissions
    // Note: Android 11+ (API 30+) handles storage differently, 
    // but path_provider + getTemporaryDirectory usually works fine without explicit storage perm.
    // We request install packages permission just in case.
    await Permission.requestInstallPackages.request();

    try {
      print("Downloading update from: $url");
      
      // Download the file
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Save to temporary storage
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/update.apk');
        
        // Write the file to disk
        await file.writeAsBytes(response.bodyBytes);
        print("Download complete. Saved to: ${file.path}");

        // --- FIXED SECTION ---
        // Create an instance of the installer
        final FlutterAppInstaller installer = FlutterAppInstaller();
        
        // Launch the native installer
        await installer.installApk(filePath: file.path);
        // ---------------------
        
      } else {
        print("Download failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Installation error: $e");
    }
  }
}