import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../services/database_service.dart';
import '../../services/update_service.dart';
import '../../models/brewing_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    // Check for updates silently on startup
    _updateService.checkForUpdates((downloadUrl) {
      _showUpdateDialog(downloadUrl);
    });
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available"),
        content: const Text("A new version of the Kaong Monitor is available."),
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Kaong Live Monitor"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<BrewingState>(
        stream: _dbService.brewingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Connection Error"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final state = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Main Status Card with Circular Timer
                _buildStatusCard(state),
                const SizedBox(height: 25),
                const Text("Sensor Telemetry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                // 2. Sensor Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSensorCard("Temperature", "${state.temperature}°C", Icons.thermostat, Colors.orange),
                    _buildSensorCard("pH Level", "${state.phLevel}", Icons.water_drop, Colors.blue),
                    _buildSensorCard("Gravity", "${state.specificGravity}", Icons.scale, Colors.green),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BrewingState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 10.0,
            percent: state.progressPercentage,
            center: Text("${(state.progressPercentage * 100).toInt()}%"),
            progressColor: Colors.deepPurple,
            backgroundColor: Colors.deepPurple.shade50,
            animation: true,
            animateFromLastPercent: true,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Current Process", style: TextStyle(color: Colors.grey)),
                Text(state.currentProcess, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Est. Completion:\n${DateTime.fromMillisecondsSinceEpoch(state.startTimestamp).add(Duration(hours: state.targetDurationHours)).toString().substring(0, 16)}", 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}