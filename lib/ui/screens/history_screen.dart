import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  final String sensorName; // e.g., "Temperature"
  final String sensorKey;  // e.g., "temperature" (matches database key)
  final String unit;       // e.g., "°C"
  final Color themeColor;

  const HistoryScreen({
    super.key,
    required this.sensorName,
    required this.sensorKey,
    required this.unit,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    // Reference to the separate history node
    final historyRef = FirebaseDatabase.instance.ref('kaong_history');

    return Scaffold(
      appBar: AppBar(
        title: Text("$sensorName History"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: themeColor.withOpacity(0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Time Logged", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Value", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // The Live List
          Expanded(
            child: FirebaseAnimatedList(
              query: historyRef.limitToLast(50), // Only show last 50 entries
              sort: (a, b) {
                // Sort by time (Newest on top)
                return b.key!.compareTo(a.key!);
              },
              itemBuilder: (context, snapshot, animation, index) {
                final data = snapshot.value as Map;
                final timestamp = data['timestamp'] ?? 0;
                final value = data[sensorKey] ?? 0;

                // Format Time
                final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                final timeString = DateFormat('MMM dd, hh:mm:ss a').format(date);

                return SizeTransition(
                  sizeFactor: animation,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.access_time, size: 16, color: Colors.grey),
                    title: Text(timeString, style: const TextStyle(fontSize: 14)),
                    trailing: Text(
                      "$value $unit",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: themeColor
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}