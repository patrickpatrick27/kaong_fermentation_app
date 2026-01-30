import 'package:firebase_database/firebase_database.dart';
import '../models/brewing_state.dart';

class DatabaseService {
  final _dbRef = FirebaseDatabase.instance.ref();

  // UPDATED: Now requires a 'machineId' to know which machine to listen to
  Stream<BrewingState> getBrewingStream(String machineId) {
    // Connects to: machines/machine_001, machines/machine_002, etc.
    return _dbRef.child('machines').child(machineId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data == null) {
        return BrewingState(
            currentProcess: "Connecting to $machineId...",
            temperature: 0, 
            phLevel: 0, 
            specificGravity: 0,
            startTimestamp: DateTime.now().millisecondsSinceEpoch, 
            targetDurationHours: 72,
            timeRemainingLabel: "Waiting for signal..."
        );
      }
      return BrewingState.fromMap(data);
    });
  }
}