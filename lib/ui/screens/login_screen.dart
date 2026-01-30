import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();

  void _login() {
    if (_controller.text.trim().isEmpty) return;
    
    // Navigate to Dashboard, passing the Machine ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(machineId: _controller.text.trim()),
      ),
    );
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
              Icon(Icons.wine_bar, size: 80, color: Colors.deepPurple),
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
                  prefixIcon: Icon(Icons.qr_code),
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
                  onPressed: _login,
                  child: Text("Connect to Machine", style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Text("Try: machine_001, machine_002, or machine_003", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}