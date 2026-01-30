import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'ui/screens/login_screen.dart'; // <--- Import the Login Screen

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
            // UPDATED: Start at LoginScreen
            return const LoginScreen(); 
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}