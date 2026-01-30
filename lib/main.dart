import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart'; // Ensure this file exists
import 'ui/screens/login_screen.dart'; // Ensure this file exists
import 'services/update_service.dart'; // Ensure this file exists

void main() async { // ADDED async
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve splash screen until Firebase loads
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize Firebase before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const KaongBrewingApp());
}

class KaongBrewingApp extends StatelessWidget {
  const KaongBrewingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Remove splash screen now that we are building the UI
    FlutterNativeSplash.remove();

    return MaterialApp(
      title: 'Kaong Wine Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, 
      // Wrap LoginScreen with the Update Checker
      home: const UpdateCheckWrapper(
        child: LoginScreen(),
      ),
    );
  }
}

/// A wrapper widget that checks for updates ONCE when the app starts
class UpdateCheckWrapper extends StatefulWidget {
  final Widget child;
  
  const UpdateCheckWrapper({
    super.key, 
    required this.child
  });

  @override
  State<UpdateCheckWrapper> createState() => _UpdateCheckWrapperState();
}

class _UpdateCheckWrapperState extends State<UpdateCheckWrapper> {
  // Static flag to ensure we only check once per app session
  static bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    if (!_hasChecked) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    _hasChecked = true; // Mark as checked immediately
    
    final updateService = UpdateService();
    
    try {
      // 1. Check GitHub for updates
      final downloadUrl = await updateService.checkForUpdate();

      // 2. If update found and widget is still mounted, show dialog
      if (downloadUrl != null && mounted) {
        _showUpdateDialog(downloadUrl, updateService);
      }
    } catch (e) {
      debugPrint("Update check failed silently: $e");
    }
  }

  void _showUpdateDialog(String url, UpdateService service) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available 🚀"),
        content: const Text(
          "A newer version of Kaong Monitor is available.\n\n"
          "Please update to ensure the app works correctly."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.downloadUpdate(url);
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}