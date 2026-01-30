import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTS ---
import '../../services/database_service.dart';
import '../../models/brewing_state.dart';
import '../widgets/process_timer.dart'; 
import '../widgets/sensor_card.dart';   
import 'graph_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String machineId; 

  const DashboardScreen({super.key, required this.machineId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();

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
          title: Column(
            children: [
              Text("KAONG MONITOR", 
                style: GoogleFonts.poppins(
                  fontSize: 18, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.white, 
                  letterSpacing: 1.2
                )
              ),
              Text(widget.machineId, 
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
            GraphScreen(machineId: widget.machineId), 
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return StreamBuilder<BrewingState>(
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
              Text("LIVE SENSORS", 
                style: GoogleFonts.poppins(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: Colors.grey[600], 
                  letterSpacing: 1.0
                )
              ),
              const SizedBox(height: 15),
              
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SensorCard(
                    title: "Temperature", 
                    value: state.temperature.toStringAsFixed(1), 
                    unit: "°C",
                    icon: Icons.thermostat, 
                    color: Colors.orange, 
                    machineId: widget.machineId,
                    dbKey: "temperature", 
                  ),
                  SensorCard(
                    title: "pH Level", 
                    value: state.phLevel.toStringAsFixed(2), 
                    unit: "",
                    icon: Icons.water_drop, 
                    color: Colors.blue, 
                    machineId: widget.machineId,
                    dbKey: "ph_level", 
                  ),
                  SensorCard(
                    title: "Gravity", 
                    value: state.specificGravity.toStringAsFixed(3), 
                    unit: "",
                    icon: Icons.scale, 
                    color: Colors.green, 
                    machineId: widget.machineId,
                    dbKey: "specific_gravity", 
                  ),
                  
                  // --- CLEAN STATUS CARD ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.15), 
                          blurRadius: 20, 
                          offset: const Offset(0, 10)
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icon Header (Top Left)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.science, color: Colors.purple, size: 24),
                          ),
                          
                          // Process Info (Bottom Left)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.currentProcess,
                                style: GoogleFonts.poppins(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.purple
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Status",
                                style: GoogleFonts.poppins(
                                  fontSize: 12, 
                                  color: Colors.grey[600]
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4527A0).withOpacity(0.15), 
            blurRadius: 20, 
            offset: const Offset(0, 8)
          )
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
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF4527A0))
            ),
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
                Text("REMAINING TIME", 
                  style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)
                ),
                const SizedBox(height: 4),
                LiveActiveTimer(
                  startTimestamp: state.startTimestamp, 
                  targetHours: state.targetDurationHours
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "Target: ${state.targetDurationHours}h", 
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}