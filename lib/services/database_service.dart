// File: lib/services/database_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/brewing_state.dart';

class DatabaseService {
  // Reference to the main node in your JSON tree
  final _dbRef = FirebaseDatabase.instance.ref();

  // Stream allows the UI to update automatically whenever Firebase changes
  Stream<BrewingState> get brewingStream {
    return _dbRef.child('kaong_brewery').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data == null) {
        // Return a "safe" default state if the database is empty or offline
        return BrewingState(
            currentProcess: "System Offline",
            temperature: 0, 
            phLevel: 0, 
            specificGravity: 0,
            startTimestamp: DateTime.now().millisecondsSinceEpoch, 
            targetDurationHours: 1,
            timeRemainingLabel: "Waiting for connection..." // <--- ADDED THIS
        );
      }
      return BrewingState.fromMap(data);
    });
  }
}