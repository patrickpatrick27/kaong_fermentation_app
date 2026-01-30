import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class GraphScreen extends StatefulWidget {
  final String machineId; // <--- NEW: Requires Machine ID

  const GraphScreen({
    super.key, 
    required this.machineId // <--- Update Constructor
  });

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  String _selectedMetric = 'temperature'; 
  List<DataPoint> _dataPoints = [];
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _activateListeners();
  }
  
  // Reload listeners if the widget updates (e.g. machineId changes)
  @override
  void didUpdateWidget(GraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machineId != widget.machineId) {
      _subscription.cancel();
      _activateListeners();
    }
  }

  void _activateListeners() {
    // UPDATED REFERENCE: Points to history/machine_001 (or whatever ID is passed)
    final ref = FirebaseDatabase.instance
        .ref('history')
        .child(widget.machineId) // <--- Use the ID here
        .limitToLast(20);
    
    _subscription = ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        if (mounted) setState(() => _dataPoints = []);
        return;
      }

      final List<DataPoint> tempPoints = [];
      
      data.forEach((key, value) {
        final entry = value as Map;
        double yVal = 0;
        if (_selectedMetric == 'temperature') yVal = (entry['temperature'] ?? 0).toDouble();
        if (_selectedMetric == 'ph_level') yVal = (entry['ph_level'] ?? 0).toDouble();
        if (_selectedMetric == 'specific_gravity') yVal = (entry['specific_gravity'] ?? 0).toDouble();

        tempPoints.add(DataPoint(
          timestamp: (entry['timestamp'] ?? 0).toDouble(),
          value: yVal,
        ));
      });

      tempPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _dataPoints = tempPoints;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToggle('Temp', 'temperature', Colors.orange),
              const SizedBox(width: 10),
              _buildToggle('pH', 'ph_level', Colors.blue),
              const SizedBox(width: 10),
              _buildToggle('Gravity', 'specific_gravity', Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: _dataPoints.isEmpty
                ? const Center(child: Text("Waiting for data..."))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints.map((e) => FlSpot(e.timestamp, e.value)).toList(),
                          isCurved: true,
                          color: _getColor(),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _getColor().withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text("Live Trend for ${widget.machineId}", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, String key, Color color) {
    final isSelected = _selectedMetric == key;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
      ),
      onPressed: () {
        setState(() {
          _selectedMetric = key;
          _activateListeners();
        });
      },
      child: Text(label),
    );
  }

  Color _getColor() {
    if (_selectedMetric == 'temperature') return Colors.orange;
    if (_selectedMetric == 'ph_level') return Colors.blue;
    return Colors.green;
  }
}

class DataPoint {
  final double timestamp;
  final double value;
  DataPoint({required this.timestamp, required this.value});
}