import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart'; // Required for verification
import 'dashboard_screen.dart';
import '../../services/update_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  final UpdateService _updateService = UpdateService();
  bool _isLoading = false; // To show a spinner while checking

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final String? downloadUrl = await _updateService.checkForUpdate();
    if (downloadUrl != null && mounted) {
      _showUpdateDialog(downloadUrl);
    }
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available 🚀"),
        content: const Text("A new version of Kaong Monitor is available."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Later")),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateService.downloadUpdate(url);
            },
            child: const Text("Update Now"),
          )
        ],
      ),
    );
  }

  // --- 🔒 NEW: VERIFY MACHINE ID BEFORE LOGIN ---
  Future<void> _verifyAndLogin() async {
    final machineId = _controller.text.trim();
    if (machineId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Check if this machine exists in the database
      final ref = FirebaseDatabase.instance.ref('brewing_state').child(machineId);
      final snapshot = await ref.get();

      if (!mounted) return;

      if (snapshot.exists) {
        // ✅ VALID: Proceed to Dashboard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(machineId: machineId),
          ),
        );
      } else {
        // ❌ INVALID: Show Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Machine ID '$machineId' not found."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wine_bar, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                "Kaong Monitor",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: "Enter Machine ID",
                  hintText: "e.g., machine_001",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _verifyAndLogin, // Disable button if loading
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Connect to Machine", style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Try: machine_001", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}