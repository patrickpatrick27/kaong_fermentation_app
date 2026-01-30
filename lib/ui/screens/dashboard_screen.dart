import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../services/database_service.dart';
import '../../services/update_service.dart';
import '../../models/brewing_state.dart';
import 'history_screen.dart'; // <--- IMPORT THE HISTORY SCREEN

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Kaong Wine Fermentation Monitor"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<BrewingState>(
        stream: _dbService.brewingStream,
        builder: (context, snapshot) {
          // 1. Error Handling
          if (snapshot.hasError) {
            return Center(child: Text("Connection Error: ${snapshot.error}"));
          }
          
          // 2. Loading State
          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Syncing with Sensors...")
                ],
              ),
            );
          }

          final state = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Main Status Card with Circular Timer
                _buildStatusCard(state),
                
                const SizedBox(height: 25),
                const Text("Sensor Telemetry", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 15),
                
                // 2. Sensor Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1, // Adjusts the shape of the cards
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Clickable Cards (Pass dbKey and unit)
                    _buildSensorCard("Temperature", "${state.temperature.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orange, "temperature", "°C"),
                    _buildSensorCard("pH Level", state.phLevel.toStringAsFixed(2), Icons.water_drop, Colors.blue, "ph_level", ""),
                    _buildSensorCard("Gravity", state.specificGravity.toStringAsFixed(3), Icons.scale, Colors.green, "specific_gravity", ""),
                    
                    // Status Card (Not clickable, so we build it manually or pass nulls if we modified the function differently)
                    // I will use a simple container here for the non-clickable status
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                           BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.science, size: 28, color: Colors.purple),
                          ),
                           const SizedBox(height: 12),
                           Text(state.currentProcess, 
                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), 
                             textAlign: TextAlign.center
                           ),
                           const SizedBox(height: 4),
                           const Text("Current Status", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
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
        boxShadow: [
          BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 55.0,
            lineWidth: 10.0,
            percent: state.progressPercentage,
            center: Text(
              "${(state.progressPercentage * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            progressColor: Colors.deepPurple,
            backgroundColor: Colors.deepPurple.shade50,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animateFromLastPercent: true,
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Time Remaining", 
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                
                // --- THE NEW DYNAMIC TEXT ---
                const SizedBox(height: 4),
                Text(
                  state.timeRemainingLabel, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // -----------------------------
                
                const SizedBox(height: 8),
                Text("Target: ${state.targetDurationHours} Hours", 
                     style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // UPDATED: Now accepts dbKey and unit to enable navigation
  Widget _buildSensorCard(String title, String value, IconData icon, Color color, String dbKey, String unit) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Navigate to History Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryScreen(
                sensorName: title,
                sensorKey: dbKey,
                unit: unit,
                themeColor: color,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // color: Colors.white, // Color is handled by Card default or theme
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}