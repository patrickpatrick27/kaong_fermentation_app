import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';
import 'control_screen.dart';
import 'graph_screen.dart'; // 👈 Contains GraphController
import 'login_screen.dart';

class HomeTabsScreen extends StatefulWidget {
  final String machineId;

  const HomeTabsScreen({super.key, required this.machineId});

  @override
  State<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen> {
  // 1. 🕹️ INSTANTIATE THE CONTROLLER
  final GraphController _graphController = GraphController();

  // 2. 📡 THE CALLBACK: Handles requests from Dashboard
  void _onHistoryRequested(String metric) {
    // A. Tell the Graph Screen to switch mode & metric
    _graphController.switchToHistory(metric);
    
    // B. Visually switch to the Analytics Tab (Index 2)
    DefaultTabController.of(context).animateTo(2); 
  }

  // 3. 🧹 CLEANUP: Always dispose controllers
  @override
  void dispose() {
    _graphController.dispose();
    super.dispose();
  }
  
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Disconnect from ${widget.machineId}?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const LoginScreen()), 
                (route) => false
              );
            }, 
            child: Text("Logout", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FA),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4527A0), Color(0xFF7B1FA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
            onPressed: _logout,
          ),
          title: Column(
            children: [
              Text("KAONG MONITOR", 
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.2)
              ),
              Text(widget.machineId, 
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)
              ),
            ],
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: const [
              Tab(text: "DASHBOARD", icon: Icon(Icons.dashboard_outlined)),
              Tab(text: "CONTROL", icon: Icon(Icons.settings_input_component)),
              Tab(text: "ANALYTICS", icon: Icon(Icons.show_chart)),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Tab 1: Dashboard (Passes the request up)
            DashboardScreen(
              machineId: widget.machineId,
              onHistoryRequest: _onHistoryRequested, // 👈 Hooked up
            ),

            // Tab 2: Control
            ControlScreen(machineId: widget.machineId),

            // Tab 3: Graph (Receives the controller)
            GraphScreen(
              machineId: widget.machineId,
              controller: _graphController, // 👈 Hooked up
            ),
          ],
        ),
      ),
    );
  }
}