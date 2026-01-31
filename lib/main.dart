import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/scheduler.dart';
// import 'package:google_fonts/google_fonts.dart'; // Not strictly used here but good to keep if used globally
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/update_service.dart';

// --- SCREENS ---
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_tabs_screen.dart'; // 👈 IMPORT THE NEW TAB SCREEN

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KaongBrewingApp());
}

class KaongBrewingApp extends StatelessWidget {
  const KaongBrewingApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return MaterialApp(
      title: 'Kaong Wine Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // 1️⃣ START HERE: Login Screen wrapped in Update Checker
      home: const UpdateCheckWrapper(child: LoginScreen()),

      // 2️⃣ DEFINED ROUTES: This makes navigation from Login -> Home much cleaner
      routes: {
        '/home': (context) => const HomeTabsScreen(machineId: 'machine_001'),
      },
    );
  }
}

// ---------------------------------------------------------
// Wrapper to Run Update Check on Startup
// ---------------------------------------------------------
class UpdateCheckWrapper extends StatefulWidget {
  final Widget child;
  const UpdateCheckWrapper({super.key, required this.child});

  @override
  State<UpdateCheckWrapper> createState() => _UpdateCheckWrapperState();
}

class _UpdateCheckWrapperState extends State<UpdateCheckWrapper> {
  static bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    if (!_hasChecked) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _checkForUpdates();
      });
    }
  }

  Future<void> _checkForUpdates() async {
    _hasChecked = true;
    final updateService = UpdateService();
    // Wrap in try-catch to prevent crashes if update server is down
    try {
      final downloadUrl = await updateService.checkForUpdate();
      if (downloadUrl != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => UpdateDialog(
            downloadUrl: downloadUrl, 
            updateService: updateService
          ),
        );
      }
    } catch (e) {
      print("Update check failed (non-critical): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ---------------------------------------------------------
// Custom Dialog Widget to handle Progress State
// ---------------------------------------------------------
class UpdateDialog extends StatefulWidget {
  final String downloadUrl;
  final UpdateService updateService;

  const UpdateDialog({
    super.key, 
    required this.downloadUrl, 
    required this.updateService
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0.0;
  bool _isDownloading = false;
  bool _hasError = false;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _progress = 0.0;
    });

    try {
      await widget.updateService.downloadUpdate(
        widget.downloadUrl,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Available 🚀"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isDownloading && !_hasError)
            const Text("A new version is available. It is recommended to update now for the best experience."),
          
          if (_hasError)
            const Text("❌ Download failed. Please check your internet and try again.", style: TextStyle(color: Colors.red)),

          if (_isDownloading) ...[
            const Text("Downloading update..."),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              color: Colors.deepPurple,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Text(
              "${(_progress * 100).toStringAsFixed(0)}%", 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
        if (!_isDownloading)
          FilledButton(
            onPressed: _startDownload,
            child: Text(_hasError ? "Retry" : "Update Now"),
          ),
      ],
    );
  }
}