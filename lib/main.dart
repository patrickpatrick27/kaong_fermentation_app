import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    // 1. Check if valid app exists
    if (Firebase.apps.isNotEmpty) {
      return Firebase.app();
    }

    try {
      // 2. FORCE THE DATABASE URL MANUALLY
      // We override the default options to guarantee it connects to Asia
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform.copyWith(
          databaseURL: 'https://kaong-fermentation-app-default-rtdb.asia-southeast1.firebasedatabase.app',
        ),
      );
    } catch (e) {
      // 3. Fail-safe: If it complains about duplicates, just use the existing one
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
          // If Connected
          if (snapshot.connectionState == ConnectionState.done) {
            return const DashboardScreen();
          }

          // If Error
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("Connection Error:\n${snapshot.error}", 
                    style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              ),
            );
          }

          // Loading
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Connecting to Asian Server..."),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}