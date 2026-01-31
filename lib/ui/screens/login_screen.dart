import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

// 👇 CHANGED: Import the Tabs Screen instead of Dashboard
import 'home_tabs_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false; 

  // --- VERIFY MACHINE ID BEFORE LOGIN ---
  Future<void> _verifyAndLogin() async {
    final machineId = _controller.text.trim();
    if (machineId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Check if machine exists in Firebase
      final ref = FirebaseDatabase.instance.ref('machines').child(machineId);
      final snapshot = await ref.get();

      if (!mounted) return;

      if (snapshot.exists) {
        // ✅ VALID: Proceed to HomeTabsScreen (The Parent of Dashboard/Control/Graph)
        // We use pushReplacement so the user can't "back" into the login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeTabsScreen(machineId: machineId),
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

  // Helper widget for Quick Fill Chips
  Widget _buildHintChip(String machineId) {
    return ActionChip(
      label: Text(machineId, style: GoogleFonts.poppins(fontSize: 12, color: Colors.deepPurple)),
      backgroundColor: Colors.deepPurple.withOpacity(0.05),
      side: BorderSide(color: Colors.deepPurple.withOpacity(0.2)),
      onPressed: () {
        _controller.text = machineId;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: Center(
        child: SingleChildScrollView( 
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
                    onPressed: _isLoading ? null : _verifyAndLogin,
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Connect to Machine", style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 30),
                
                Text("Quick Fill:", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildHintChip("machine_001"),
                    _buildHintChip("machine_002"),
                    _buildHintChip("machine_003"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}