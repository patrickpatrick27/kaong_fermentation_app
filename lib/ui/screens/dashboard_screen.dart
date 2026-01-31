import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/database_service.dart';
import '../../models/brewing_state.dart';
import '../widgets/process_timer.dart'; 
import '../widgets/sensor_card.dart';

class DashboardScreen extends StatefulWidget {
  final String machineId; 
  
  // 1. 🆕 Add the callback definition here
  final Function(String metricKey) onHistoryRequest; 

  const DashboardScreen({
    super.key, 
    required this.machineId,
    required this.onHistoryRequest, // 👈 Required now
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BrewingState>(
      stream: _dbService.getBrewingStream(widget.machineId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final state = snapshot.data!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. STATUS CARD
              _buildStatusCard(state),
              
              const SizedBox(height: 25),
              Text("LIVE SENSORS", 
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600], letterSpacing: 1.0)
              ),
              const SizedBox(height: 15),
              
              // 2. SENSOR GRID
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1, 
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // TEMPERATURE
                  SensorCard(
                    title: "Temperature", 
                    value: state.temperature.toStringAsFixed(1), 
                    unit: "°C",
                    icon: Icons.thermostat, 
                    color: Colors.orange, 
                    machineId: widget.machineId, 
                    dbKey: "temp_primary",
                    // 2. 🚀 USE THE CALLBACK DIRECTLY
                    onViewHistory: () => widget.onHistoryRequest('temperature'), 
                  ),

                  // pH LEVEL
                  SensorCard(
                    title: "pH Level", 
                    value: state.phLevel.toStringAsFixed(2), 
                    unit: "pH",
                    icon: Icons.water_drop, 
                    color: Colors.blue, 
                    machineId: widget.machineId, 
                    dbKey: "ph_level",
                    onViewHistory: () => widget.onHistoryRequest('ph_level'),
                  ),

                  // GRAVITY
                  SensorCard(
                    title: "Gravity", 
                    value: state.specificGravity.toStringAsFixed(3), 
                    unit: "SG",
                    icon: Icons.scale, 
                    color: Colors.green, 
                    machineId: widget.machineId, 
                    dbKey: "specific_gravity",
                    onViewHistory: () => widget.onHistoryRequest('specific_gravity'),
                  ),
                  
                  // SYSTEM ACTIVE CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tips_and_updates, size: 30, color: Colors.purple.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text("System Active", style: GoogleFonts.poppins(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("Monitoring...", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
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
        mainAxisAlignment: MainAxisAlignment.start,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(state.currentProcess.toUpperCase(), 
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[800], letterSpacing: 0.5)
                  ),
                ),
                const SizedBox(height: 8),
                Text("REMAINING TIME", style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w600)),
                LiveActiveTimer(startTimestamp: state.startTimestamp, targetHours: state.targetDurationHours),
                const SizedBox(height: 4),
                Text("Target: ${state.targetDurationHours}h", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          )
        ],
      ),
    );
  }
}