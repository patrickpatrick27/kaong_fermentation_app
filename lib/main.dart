import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'ui/screens/login_screen.dart';
import 'services/update_service.dart'; // <--- Import UpdateService

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const KaongBrewingApp());
}

class KaongBrewingApp extends StatefulWidget {
  const KaongBrewingApp({super.key});

  @override
  State<KaongBrewingApp> createState() => _KaongBrewingAppState();
}

class _KaongBrewingAppState extends State<KaongBrewingApp> {
  late final Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initFirebase();
  }

  Future<FirebaseApp> _initFirebase() async {
    if (Firebase.apps.isNotEmpty) return Firebase.app();
    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform.copyWith(
          databaseURL: 'https://kaong-fermentation-app-default-rtdb.asia-southeast1.firebasedatabase.app',
        ),
      );
    } catch (e) {
      if (Firebase.apps.isNotEmpty) return Firebase.app();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaong Wine Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            FlutterNativeSplash.remove();
            return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
          }
          if (snapshot.connectionState == ConnectionState.done) {
            FlutterNativeSplash.remove();
            
            // WRAPPER: Wraps LoginScreen to check for updates on startup
            return const UpdateCheckWrapper(child: LoginScreen());
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// A wrapper widget that checks for updates as soon as the app loads
class UpdateCheckWrapper extends StatefulWidget {
  final Widget child;
  const UpdateCheckWrapper({super.key, required this.child});

  @override
  State<UpdateCheckWrapper> createState() => _UpdateCheckWrapperState();
}

class _UpdateCheckWrapperState extends State<UpdateCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService();
    // 1. Check GitHub for updates
    final downloadUrl = await updateService.checkForUpdate();

    // 2. If update found and widget is valid, show dialog
    if (downloadUrl != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // User must choose an option
        builder: (context) => AlertDialog(
          title: const Text("Update Available 🚀"),
          content: const Text(
            "A newer version of Kaong Monitor is available.\n\n"
            "Please update to ensure the app works correctly."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text("Later"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                updateService.downloadUpdate(downloadUrl);
              },
              child: const Text("Update Now"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}