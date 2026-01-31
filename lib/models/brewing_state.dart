class BrewingState {
  final String currentProcess;
  final double temperature;
  final double phLevel;
  final double specificGravity;
  final int startTimestamp;
  final int targetDurationHours;
  final String timeRemainingLabel; // 🕒 NEW FIELD

  BrewingState({
    required this.currentProcess,
    required this.temperature,
    required this.phLevel,
    required this.specificGravity,
    required this.startTimestamp,
    required this.targetDurationHours,
    required this.timeRemainingLabel,
  });

  factory BrewingState.fromMap(Map<dynamic, dynamic> data) {
    // 🛡️ Safety Checks: Ensure nested maps exist
    final status = data['live_status'] != null 
        ? Map<dynamic, dynamic>.from(data['live_status']) 
        : {};
    
    final sensors = data['sensors'] != null 
        ? Map<dynamic, dynamic>.from(data['sensors']) 
        : {};

    return BrewingState(
      currentProcess: status['current_process'] ?? "Ready",
      timeRemainingLabel: status['time_remaining_label'] ?? "Calculating...",
      
      startTimestamp: status['start_timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      targetDurationHours: status['target_duration_hours'] ?? 24,
      
      // 🌡️ Mapped to the Python script's keys
      temperature: (sensors['temperature'] ?? 0).toDouble(),
      phLevel: (sensors['ph_level'] ?? 0).toDouble(),
      specificGravity: (sensors['specific_gravity'] ?? 0).toDouble(),
    );
  }

  // 📊 Progress Logic
  double get progressPercentage {
    final start = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    final now = DateTime.now();
    final totalDuration = Duration(hours: targetDurationHours);
    
    if (totalDuration.inMinutes == 0) return 0.0;

    final elapsed = now.difference(start);
    double percent = elapsed.inMinutes / totalDuration.inMinutes;
    
    return percent.clamp(0.0, 1.0); // Ensures it stays between 0 and 1
  }
}