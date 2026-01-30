import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveActiveTimer extends StatefulWidget {
  final int startTimestamp;
  final int targetHours;

  const LiveActiveTimer({
    super.key, 
    required this.startTimestamp, 
    required this.targetHours
  });

  @override
  State<LiveActiveTimer> createState() => _LiveActiveTimerState();
}

class _LiveActiveTimerState extends State<LiveActiveTimer> {
  late Timer _timer;
  String _displayText = "Calculating...";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final start = DateTime.fromMillisecondsSinceEpoch(widget.startTimestamp);
    final end = start.add(Duration(hours: widget.targetHours));
    final now = DateTime.now();
    
    final remaining = end.difference(now);

    if (remaining.isNegative) {
      if (mounted && _displayText != "Complete") {
        setState(() => _displayText = "Complete");
      }
      return;
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (mounted) {
      setState(() {
        _displayText = "${days}d ${hours}h ${minutes}m ${seconds}s";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: GoogleFonts.poppins(
        fontSize: 18, 
        fontWeight: FontWeight.bold, 
        color: const Color(0xFF2D2D2D),
        fontFeatures: [const FontFeature.tabularFigures()], // Keeps numbers from jittering
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}