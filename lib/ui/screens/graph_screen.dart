import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class GraphScreen extends StatefulWidget {
  final String machineId;

  const GraphScreen({
    super.key, 
    required this.machineId 
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
  
  @override
  void didUpdateWidget(GraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machineId != widget.machineId) {
      _subscription.cancel();
      _activateListeners();
    }
  }

  void _activateListeners() {
    final ref = FirebaseDatabase.instance
        .ref('history')
        .child(widget.machineId)
        .orderByChild('timestamp')
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
        
        // Safety check: ensure values exist and are doubles
        if (_selectedMetric == 'temperature') yVal = (entry['temperature'] ?? 0).toDouble();
        if (_selectedMetric == 'ph_level') yVal = (entry['ph_level'] ?? 0).toDouble();
        if (_selectedMetric == 'specific_gravity') yVal = (entry['specific_gravity'] ?? 0).toDouble();

        // Use index as X-axis for simplicity in this view, or timestamp if you prefer
        // Here we store timestamp for sorting, but we might chart using index 0..N
        tempPoints.add(DataPoint(
          timestamp: (entry['timestamp'] ?? 0).toDouble(),
          value: yVal,
        ));
      });

      // Sort by time
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

  // --- 📐 NORMALIZATION LOGIC ---
  List<double> _getMinMax() {
    if (_dataPoints.isEmpty) return [0, 10];

    double min = _dataPoints.first.value;
    double max = _dataPoints.first.value;

    for (var p in _dataPoints) {
      if (p.value < min) min = p.value;
      if (p.value > max) max = p.value;
    }

    double range = max - min;
    
    // If line is flat (e.g. all 0.990), add artificial buffer
    if (range == 0) return [min - 0.1, max + 0.1];

    // Add 20% padding
    double padding = range * 0.2;
    return [min - padding, max + padding];
  }

  @override
  Widget build(BuildContext context) {
    // Calculate range for this render
    final minMax = _getMinMax();
    final double minY = minMax[0];
    final double maxY = minMax[1];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Toggle Buttons ---
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggle('Temp', 'temperature', Colors.orange),
                const SizedBox(width: 5),
                _buildToggle('pH', 'ph_level', Colors.blue),
                const SizedBox(width: 5),
                _buildToggle('Gravity', 'specific_gravity', Colors.green),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // --- The Graph ---
          Expanded(
            child: _dataPoints.isEmpty
                ? Center(child: Text("Waiting for data...", style: GoogleFonts.poppins(color: Colors.grey)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true, 
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true, 
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == minY || value == maxY) return const SizedBox.shrink();
                              return Text(
                                value.toStringAsFixed(_selectedMetric == 'specific_gravity' ? 3 : 1),
                                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
                              );
                            }
                          )
                        ),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      
                      // 🚀 APPLY NORMALIZATION HERE
                      minY: minY,
                      maxY: maxY,

                      lineBarsData: [
                        LineChartBarData(
                          // Map sorted data to 0,1,2... X-axis for even spacing
                          spots: _dataPoints.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.value);
                          }).toList(),
                          isCurved: true,
                          color: _getColor(),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _getColor().withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            "Live Trend for ${widget.machineId}", 
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, String key, Color color) {
    final isSelected = _selectedMetric == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetric = key;
          _activateListeners(); // Refresh data for new metric
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
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