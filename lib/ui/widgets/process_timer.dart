import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../theme/app_theme.dart';
import '../../models/brewing_state.dart';
import 'package:intl/intl.dart';

class ProcessTimer extends StatelessWidget {
  final BrewingState state;

  const ProcessTimer({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Calculate End Time
    final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(state.startTimestamp);
    final DateTime endTime = startTime.add(Duration(hours: state.targetDurationHours));
    final String formattedEnd = DateFormat('MMM dd, hh:mm a').format(endTime);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 55.0,
            lineWidth: 10.0,
            percent: state.progressPercentage, // 0.0 to 1.0
            center: Text(
              "${(state.progressPercentage * 100).toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            progressColor: AppTheme.accentColor,
            backgroundColor: Colors.white24,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "CURRENT PHASE",
                    style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.0),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentProcess,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "Ends: $formattedEnd",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}