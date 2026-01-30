import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  final String machineId;  // <--- NEW: Requires Machine ID
  final String sensorName; 
  final String sensorKey;  
  final String unit;       
  final Color themeColor;

  const HistoryScreen({
    super.key,
    required this.machineId, // <--- Update Constructor
    required this.sensorName,
    required this.sensorKey,
    required this.unit,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    // UPDATED REFERENCE: history/machine_001
    final historyRef = FirebaseDatabase.instance
        .ref('history')
        .child(machineId); // <--- Use the ID here

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$sensorName History", style: const TextStyle(fontSize: 18)),
            Text(machineId, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
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
          
          Expanded(
            child: FirebaseAnimatedList(
              query: historyRef.limitToLast(50),
              sort: (a, b) {
                return b.key!.compareTo(a.key!);
              },
              itemBuilder: (context, snapshot, animation, index) {
                final data = snapshot.value as Map;
                final timestamp = data['timestamp'] ?? 0;
                final value = data[sensorKey] ?? 0;

                final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                final timeString = DateFormat('MMM dd, hh:mm:ss a').format(date);

                return SizeTransition(
                  sizeFactor: animation,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.access_time, size: 16, color: Colors.grey),
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