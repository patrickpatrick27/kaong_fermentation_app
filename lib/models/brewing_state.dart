// File: lib/models/brewing_state.dart
class BrewingState {
  final String currentProcess;
  final double temperature;
  final double phLevel;
  final double specificGravity;
  final int startTimestamp;
  final int targetDurationHours;

  BrewingState({
    required this.currentProcess,
    required this.temperature,
    required this.phLevel,
    required this.specificGravity,
    required this.startTimestamp,
    required this.targetDurationHours,
  });

  // Factory to parse Firebase Snapshot
  factory BrewingState.fromMap(Map<dynamic, dynamic> data) {
    final sensors = data['sensors'] ?? {};
    final status = data['live_status'] ?? {};

    return BrewingState(
      currentProcess: status['current_process'] ?? 'Idle',
      // Ensure we convert to double, even if Firebase sends an integer (e.g. 28)
      temperature: (sensors['temperature'] ?? 0).toDouble(),
      phLevel: (sensors['ph_level'] ?? 0).toDouble(),
      specificGravity: (sensors['specific_gravity'] ?? 0).toDouble(),
      startTimestamp: status['start_timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      targetDurationHours: status['target_duration_hours'] ?? 1,
    );
  }

  // Logic to calculate how full the progress bar should be (0.0 to 1.0)
  double get progressPercentage {
    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    final now = DateTime.now();
    final elapsedMinutes = now.difference(startTime).inMinutes;
    final totalMinutes = targetDurationHours * 60;
    
    if (totalMinutes <= 0) return 0.0;
    
    double percent = elapsedMinutes / totalMinutes;
    // Clamp ensures it never goes below 0% or above 100%
    return percent.clamp(0.0, 1.0); 
  }
}