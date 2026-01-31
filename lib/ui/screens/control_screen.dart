import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/hardware_control_card.dart';

class ControlScreen extends StatefulWidget {
  final String machineId;

  const ControlScreen({super.key, required this.machineId});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  // Helper to send hardware commands
  void _sendCommand(String component, Map<String, dynamic> data) {
    FirebaseDatabase.instance
        .ref('commands/${widget.machineId}/$component')
        .update(data);
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ We create a NEW stream here every time build runs, or listen to .onValue directly
    // .onValue returns a BroadcastStream, which prevents the "Bad State" error.
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('machines/${widget.machineId}/hardware').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("Connecting to Hardware...", style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          );
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        Map getDevice(String key) => data[key] != null ? Map<String, dynamic>.from(data[key]) : {};

        final quartz = getDevice('heater_quartz');
        final immersion = getDevice('heater_immersion');
        final mixer = getDevice('mixer_worm_gear');
        final valve = getDevice('valve_solenoid');
        final servo = getDevice('servo_yeast');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header("HEATING SYSTEMS"),
              HardwareControlCard(
                title: "Quartz Infrared Tubes",
                subtitle: "28cm Tubes (x4)",
                icon: Icons.sunny, // Standard icon
                color: Colors.orange,
                value: quartz['active'] ?? false,
                isAvailable: quartz['available'] ?? false,
                sliderValue: (quartz['power'] ?? 0).toDouble(),
                onToggle: (v) => _sendCommand('heater_quartz', {'state': v}),
                onSliderChanged: (v) => _sendCommand('heater_quartz', {'state': true, 'value': v.toInt()}),
              ),
              HardwareControlCard(
                title: "Immersion Heater",
                subtitle: "Pasteurization Element",
                icon: Icons.hot_tub, // Use standard Material icon
                color: Colors.red,
                value: immersion['active'] ?? false,
                isAvailable: immersion['available'] ?? false,
                sliderValue: (immersion['power'] ?? 0).toDouble(),
                onToggle: (v) => _sendCommand('heater_immersion', {'state': v}),
                onSliderChanged: (v) => _sendCommand('heater_immersion', {'state': true, 'value': v.toInt()}),
              ),

              const SizedBox(height: 10),
              _header("MECHANICAL"),
              HardwareControlCard(
                title: "Worm Gear Mixer",
                subtitle: "40 RPM Motor",
                icon: Icons.cyclone,
                color: Colors.blue,
                value: mixer['active'] ?? false,
                isAvailable: mixer['available'] ?? false,
                sliderValue: (mixer['speed'] ?? 0).toDouble(),
                onToggle: (v) => _sendCommand('mixer_worm_gear', {'state': v}),
                onSliderChanged: (v) => _sendCommand('mixer_worm_gear', {'state': true, 'value': v.toInt()}),
              ),
              HardwareControlCard(
                title: "Yeast Servo",
                subtitle: "MG996R Dispenser",
                icon: Icons.local_dining,
                color: Colors.brown,
                value: servo['dispensed'] ?? false,
                isAvailable: servo['available'] ?? false,
                onToggle: (v) => _sendCommand('servo_yeast', {'dispense': v}),
              ),

              const SizedBox(height: 10),
              _header("FLUID CONTROL"),
              HardwareControlCard(
                title: "Solenoid Valve",
                subtitle: "Output Flow Control",
                icon: Icons.water_damage,
                color: Colors.purple,
                value: valve['open'] ?? false,
                isAvailable: valve['available'] ?? false,
                onToggle: (v) => _sendCommand('valve_solenoid', {'open': v}),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}