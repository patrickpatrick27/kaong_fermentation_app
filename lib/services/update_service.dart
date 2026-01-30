import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // ⚠️ YOUR GITHUB CONFIGURATION
  final String userName = "patrickpatrick27"; 
  final String repoName = "kaong_fermentation_app"; 

  /// Checks GitHub for releases. Returns the download URL if a new version exists.
  Future<String?> checkForUpdate() async {
    try {
      // 1. Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      Version currentVersion = Version.parse(packageInfo.version);
      print("📱 Current App Version: $currentVersion");

      // 2. Query GitHub API for the latest release
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$userName/$repoName/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestTag = data['tag_name']; // e.g. "v1.0.12"

        // Remove 'v' prefix if present
        if (latestTag.startsWith('v')) {
          latestTag = latestTag.substring(1);
        }

        Version latestVersion = Version.parse(latestTag);
        print("☁️ Latest GitHub Version: $latestVersion");

        // 3. Compare: Is GitHub version > Current version?
        if (latestVersion > currentVersion) {
          List assets = data['assets'];
          // Find the APK file in the release assets
          final apkAsset = assets.firstWhere(
            (asset) => asset['name'].toString().endsWith(".apk"),
            orElse: () => null,
          );

          if (apkAsset != null) {
            return apkAsset['browser_download_url'];
          }
        }
      } else {
        print("⚠️ Failed to fetch releases: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error checking for updates: $e");
    }
    return null; // No update found or error occurred
  }

  /// Opens the browser to download the update
  Future<void> downloadUpdate(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch $url");
    }
  }
}