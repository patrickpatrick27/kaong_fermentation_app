import 'package:flutter/material.dart';

class SelectionService {
  // Singleton pattern (One instance for the whole app)
  static final SelectionService _instance = SelectionService._internal();
  factory SelectionService() => _instance;
  SelectionService._internal();

  // The currently selected metric (default to temperature)
  final ValueNotifier<String> selectedMetric = ValueNotifier<String>('temperature');

  void select(String metric) {
    selectedMetric.value = metric;
  }
}