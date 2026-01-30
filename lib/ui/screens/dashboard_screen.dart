import 'dart:async'; // Required for the Timer
import 'dart:ui';    // Required for tabular figures (prevent number jumping)
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/database_service.dart';
import '../../services/update_service.dart';
import '../../models/brewing_state.dart';
import 'history_screen.dart';
import 'graph_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String machineId; // The ID of the machine we are watching

  const DashboardScreen({super.key, required this.machineId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    _updateService.checkForUpdates((downloadUrl) {
      if (mounted) _showUpdateDialog(downloadUrl);
    });
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available"),
        content: const Text("A new version of the Kaong Wine Monitor is available."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateService.downloadAndInstall(url);
            },
            child: const Text("Update Now"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
          // UPDATED TITLE: Shows the specific Machine ID
          title: Column(
            children: [
              Text("KAONG MONITOR", 
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.2)
              ),
              Text(widget.machineId, // Displays "machine_001" etc.
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)
              ),
            ],
          ),
          centerTitle: true,
          elevation: 4,
          bottom: TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "DASHBOARD", icon: Icon(Icons.dashboard_outlined)),
              Tab(text: "ANALYTICS", icon: Icon(Icons.show_chart)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(),
            // Pass the ID to the Graph Screen
            GraphScreen(machineId: widget.machineId), 
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return StreamBuilder<BrewingState>(
      // Pass the ID to the Stream
      stream: _dbService.getBrewingStream(widget.machineId), 
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Connection Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final state = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(state),
              const SizedBox(height: 25),
              Text("LIVE SENSORS", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 1.0)),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSensorCard("Temperature", "${state.temperature.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orange, "temperature", "°C"),
                  _buildSensorCard("pH Level", state.phLevel.toStringAsFixed(2), Icons.water_drop, Colors.blue, "ph_level", ""),
                  _buildSensorCard("Gravity", state.specificGravity.toStringAsFixed(3), Icons.scale, Colors.green, "specific_gravity", ""),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.science, size: 28, color: Colors.purple)),
                         const SizedBox(height: 12),
                         Text(state.currentProcess, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                         const SizedBox(height: 4),
                         Text("Status", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BrewingState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF4527A0).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 55.0,
            lineWidth: 10.0,
            percent: state.progressPercentage,
            center: Text("${(state.progressPercentage * 100).toInt()}%", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF4527A0))),
            progressColor: const Color(0xFF4527A0),
            backgroundColor: const Color(0xFFEDE7F6),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animateFromLastPercent: true,
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("REMAINING TIME", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                
                // --- REPLACED STATIC TEXT WITH LIVE TIMER ---
                LiveActiveTimer(
                  startTimestamp: state.startTimestamp, 
                  targetHours: state.targetDurationHours
                ),
                // -------------------------------------------------

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Text("Target: ${state.targetDurationHours}h", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, Color color, String dbKey, String unit) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => 
            HistoryScreen(
              machineId: widget.machineId, 
              sensorName: title, 
              sensorKey: dbKey, 
              unit: unit, 
              themeColor: color
            )
          ));
        },
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 28, color: color)),
              const SizedBox(height: 12),
              Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)), const SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey[300])]),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NEW WIDGET: HANDLES THE LIVE TICKING ---
class LiveActiveTimer extends StatefulWidget {
  final int startTimestamp;
  final int targetHours;

  const LiveActiveTimer({super.key, required this.startTimestamp, required this.targetHours});

  @override
  State<LiveActiveTimer> createState() => _LiveActiveTimerState();
}

class _LiveActiveTimerState extends State<LiveActiveTimer> {
  late Timer _timer;
  String _displayText = "Calculating...";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final start = DateTime.fromMillisecondsSinceEpoch(widget.startTimestamp);
    final end = start.add(Duration(hours: widget.targetHours));
    final now = DateTime.now();
    
    final remaining = end.difference(now);

    if (remaining.isNegative) {
      if (mounted && _displayText != "Complete") {
        setState(() => _displayText = "Complete");
      }
      return;
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (mounted) {
      setState(() {
        // Format: 1d 4h 20m 30s
        _displayText = "${days}d ${hours}h ${minutes}m ${seconds}s";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: GoogleFonts.poppins(
        fontSize: 18, 
        fontWeight: FontWeight.bold, 
        color: const Color(0xFF2D2D2D),
        // This stops the text from jittering as the numbers change width
        fontFeatures: [const FontFeature.tabularFigures()], 
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}