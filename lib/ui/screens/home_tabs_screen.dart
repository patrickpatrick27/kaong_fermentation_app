import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';
import 'control_screen.dart';
import 'graph_screen.dart'; 
import 'login_screen.dart';

class HomeTabsScreen extends StatefulWidget {
  final String machineId;

  const HomeTabsScreen({super.key, required this.machineId});

  @override
  State<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen> with SingleTickerProviderStateMixin {
  
  final GraphController _graphController = GraphController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _onHistoryRequested(String metric) {
    _graphController.switchToHistory(metric);
    _tabController.animateTo(2); 
  }

  @override
  void dispose() {
    _graphController.dispose();
    _tabController.dispose(); 
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
    return Scaffold(
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
        // ❌ Leading removed
        automaticallyImplyLeading: false, // Prevents back arrow if one appears
        
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
        
        // 👇 LOGOUT BUTTON MOVED HERE (Upper Right)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
            onPressed: _logout,
          ),
          const SizedBox(width: 8), // Small padding from the edge
        ],

        bottom: TabBar(
          controller: _tabController, 
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
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DashboardScreen(
            machineId: widget.machineId,
            onHistoryRequest: _onHistoryRequested, 
          ),
          ControlScreen(machineId: widget.machineId),
          GraphScreen(
            machineId: widget.machineId,
            controller: _graphController, 
          ),
        ],
      ),
    );
  }
}