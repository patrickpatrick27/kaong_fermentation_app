class BrewingState {
  final String currentProcess;
  final double temperature;
  final double phLevel;
  final double specificGravity;
  final int startTimestamp;
  final int targetDurationHours;
  final String timeRemainingLabel; // <--- NEW FIELD

  BrewingState({
    required this.currentProcess,
    required this.temperature,
    required this.phLevel,
    required this.specificGravity,
    required this.startTimestamp,
    required this.targetDurationHours,
    required this.timeRemainingLabel, // <--- REQUIRED
  });

  // Factory to convert Firebase JSON into this Object
  factory BrewingState.fromMap(Map<dynamic, dynamic> data) {
    final status = data['live_status'] ?? {};
    final sensors = data['sensors'] ?? {};

    return BrewingState(
      currentProcess: status['current_process'] ?? "Unknown",
      // If the script hasn't sent the label yet, show "Calculating..."
      timeRemainingLabel: status['time_remaining_label'] ?? "Calculating...", 
      
      startTimestamp: status['start_timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      targetDurationHours: status['target_duration_hours'] ?? 72,
      
      // Ensure values are doubles (Firebase sometimes sends integers)
      temperature: (sensors['temperature'] ?? 0).toDouble(),
      phLevel: (sensors['ph_level'] ?? 0).toDouble(),
      specificGravity: (sensors['specific_gravity'] ?? 0).toDouble(),
    );
  }

  // Helper to calculate percentage for the circular indicator
  double get progressPercentage {
    final start = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    final now = DateTime.now();
    final totalDuration = Duration(hours: targetDurationHours);
    
    final elapsed = now.difference(start);
    double percent = elapsed.inMinutes / totalDuration.inMinutes;
    
    // Clamp between 0.0 and 1.0
    if (percent < 0) return 0.0;
    if (percent > 1) return 1.0;
    return percent;
  }
}