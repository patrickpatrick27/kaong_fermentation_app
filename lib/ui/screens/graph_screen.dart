import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// 1. 🕹️ CONTROLLER
class GraphController extends ChangeNotifier {
  String? requestMetric;
  bool? requestShowChart;

  void switchToHistory(String metric) {
    requestMetric = metric;
    requestShowChart = false; 
    notifyListeners();
  }
}

class GraphScreen extends StatefulWidget {
  final String machineId;
  final GraphController controller;

  const GraphScreen({
    super.key, 
    required this.machineId,
    required this.controller,
  });

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; 

  String _selectedMetric = 'temperature'; 
  bool _showChart = true; 
  List<DataPoint> _dataPoints = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _activateListeners(); 
    widget.controller.addListener(_handleControllerCommand);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerCommand);
    _subscription?.cancel();
    super.dispose();
  }

  void _handleControllerCommand() {
    final newMetric = widget.controller.requestMetric;
    final newChartMode = widget.controller.requestShowChart;
    
    if (newMetric != null && newChartMode != null) {
      if (mounted) {
        setState(() {
          _selectedMetric = newMetric;
          _showChart = newChartMode;
          if (_showChart) {
             _activateListeners();
          } else {
            _subscription?.cancel();
          }
        });
      }
    }
  }

  void _onInternalMetricChange(String key) {
    setState(() {
      _selectedMetric = key;
      if (_showChart) _activateListeners();
    });
  }

  void _onInternalViewChange(bool isChart) {
    setState(() {
      _showChart = isChart;
      if (_showChart) {
        _activateListeners();
      } else {
        _subscription?.cancel();
      }
    });
  }

  void _activateListeners() {
    _subscription?.cancel(); 
    if (!_showChart) return; 

    final ref = FirebaseDatabase.instance
        .ref('history')
        .child(widget.machineId)
        .orderByChild('timestamp')
        .limitToLast(50);
    
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
        
        double safeParse(dynamic val) {
          if (val == null) return 0.0;
          if (val is int) return val.toDouble();
          if (val is double) return val;
          if (val is String) return double.tryParse(val) ?? 0.0;
          return 0.0;
        }

        if (_selectedMetric == 'temperature') {
            yVal = safeParse(entry['temp']) != 0 ? safeParse(entry['temp']) : safeParse(entry['temperature']);
        } else if (_selectedMetric == 'ph_level') {
            yVal = safeParse(entry['ph']) != 0 ? safeParse(entry['ph']) : safeParse(entry['ph_level']);
        } else if (_selectedMetric == 'specific_gravity') {
            yVal = safeParse(entry['gravity']) != 0 ? safeParse(entry['gravity']) : safeParse(entry['specific_gravity']);
        }

        tempPoints.add(DataPoint(
          timestamp: safeParse(entry['timestamp']),
          value: yVal,
        ));
      });

      tempPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (mounted) setState(() => _dataPoints = tempPoints);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. CONTROLS
          Column(
            children: [
              SingleChildScrollView( 
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMetricToggle('Temp', 'temperature', Colors.orange),
                    const SizedBox(width: 8),
                    _buildMetricToggle('pH', 'ph_level', Colors.blue),
                    const SizedBox(width: 8),
                    _buildMetricToggle('Gravity', 'specific_gravity', Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewSegment("Chart", Icons.show_chart, true),
                    _buildViewSegment("History", Icons.list_alt, false),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 2. ANIMATED CONTENT SWITCHER 🎬
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              // Optional: Add a subtle Scale + Fade transition
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                    child: child
                  ),
                );
              },
              // The Key forces the animation to run whenever Metric OR View changes
              child: Container(
                key: ValueKey("$_selectedMetric-$_showChart"), // <--- UNIQUE KEY IS CRITICAL
                child: _showChart ? _buildChart() : _buildHistoryList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricToggle(String label, String key, Color color) {
    final isSelected = _selectedMetric == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque, 
      onTap: () => _onInternalMetricChange(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          label, 
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey, 
            fontSize: 12, 
            fontWeight: FontWeight.w600
          )
        ),
      ),
    );
  }

  Widget _buildViewSegment(String label, IconData icon, bool isChartBtn) {
    final isSelected = _showChart == isChartBtn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onInternalViewChange(isChartBtn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black87 : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label, 
              style: GoogleFonts.poppins(
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.black87 : Colors.grey
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_dataPoints.isEmpty) {
      return Center(child: Text("Waiting for data...", style: GoogleFonts.poppins(color: Colors.grey)));
    }
    
    double minY = _dataPoints.first.value;
    double maxY = _dataPoints.first.value;
    for (var p in _dataPoints) {
      if (p.value < minY) minY = p.value;
      if (p.value > maxY) maxY = p.value;
    }
    double range = maxY - minY;
    if (range == 0) range = 1.0; 
    
    final double paddedMinY = minY - (range * 0.2);
    final double paddedMaxY = maxY + (range * 0.2);
    final double minX = _dataPoints.first.timestamp;
    final double maxX = _dataPoints.last.timestamp;
    final double xRange = maxX - minX;
    final double xInterval = xRange == 0 ? 1 : xRange / 3.5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: range / 4, getTitlesWidget: (value, meta) {
             if (value < paddedMinY || value > paddedMaxY) return const SizedBox.shrink();
             return Text(value.toStringAsFixed(1), style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10));
          })),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: xInterval, getTitlesWidget: (value, meta) {
             if (value < minX || value > maxX) return const SizedBox.shrink();
             final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
             return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(DateFormat('HH:mm:ss').format(date), style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)));
          })),
        ),
        borderData: FlBorderData(show: false),
        minY: paddedMinY, maxY: paddedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: _dataPoints.map((e) => FlSpot(e.timestamp, e.value)).toList(),
            isCurved: true, color: _getColor(), barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: _getColor().withOpacity(0.15)),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    String dbKey = 'temp'; String unit = '°C'; Color color = Colors.orange;
    if (_selectedMetric == 'ph_level') { dbKey = 'ph'; unit = 'pH'; color = Colors.blue; }
    if (_selectedMetric == 'specific_gravity') { dbKey = 'gravity'; unit = 'SG'; color = Colors.green; }
    final historyRef = FirebaseDatabase.instance.ref('history').child(widget.machineId);
    
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Timestamp", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: color)), Text("Value ($unit)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: color))])),
      const SizedBox(height: 8),
      Expanded(child: FirebaseAnimatedList(query: historyRef.limitToLast(50), sort: (a, b) => b.key!.compareTo(a.key!), defaultChild: const Center(child: CircularProgressIndicator()), itemBuilder: (context, snapshot, animation, index) {
        final data = snapshot.value as Map;
        double val = 0;
        if (data.containsKey(dbKey)) { val = (data[dbKey] is int) ? (data[dbKey] as int).toDouble() : (data[dbKey] as double); } 
        else if (dbKey == 'temp' && data.containsKey('temperature')) { val = (data['temperature'] is int) ? (data['temperature'] as int).toDouble() : (data['temperature'] as double); }
        return SizeTransition(sizeFactor: animation, child: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: ListTile(dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), leading: Icon(Icons.access_time, size: 16, color: Colors.grey[400]), title: Text(DateFormat('MMM dd, hh:mm:ss a').format(DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0)), style: GoogleFonts.poppins(fontSize: 12)), trailing: Text("${val.toStringAsFixed(dbKey == 'gravity' ? 3 : 1)} $unit", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)))));
      }))
    ]);
  }

  Color _getColor() { if (_selectedMetric == 'temperature') return Colors.orange; if (_selectedMetric == 'ph_level') return Colors.blue; return Colors.green; }
}

class DataPoint { final double timestamp; final double value; DataPoint({required this.timestamp, required this.value}); }