import 'dart:async'; // Required for Debouncing
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HardwareControlCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool value;       // Value from Database (Server Truth)
  final bool isAvailable;
  final Function(bool) onToggle;
  final double? sliderValue; // Value from Database (Server Truth)
  final Function(double)? onSliderChanged;

  const HardwareControlCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.isAvailable,
    required this.onToggle,
    this.sliderValue,
    this.onSliderChanged,
  });

  @override
  State<HardwareControlCard> createState() => _HardwareControlCardState();
}

class _HardwareControlCardState extends State<HardwareControlCard> {
  // Local state for "Optimistic" UI
  late bool _localValue;
  double? _localSliderValue;
  
  // Debounce Timer for Slider
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initialize local state with server data
    _localValue = widget.value;
    _localSliderValue = widget.sliderValue;
  }

  @override
  void didUpdateWidget(HardwareControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If server updates (e.g., from another user), sync our local state
    // BUT only if we aren't currently dragging/interacting to prevent "fighting"
    if (widget.value != oldWidget.value) {
      _localValue = widget.value;
    }
    // Only sync slider if user isn't actively sliding (checked via debounce)
    if (widget.sliderValue != oldWidget.sliderValue && !(_debounce?.isActive ?? false)) {
      _localSliderValue = widget.sliderValue;
    }
  }

  void _handleToggle(bool newValue) {
    setState(() {
      _localValue = newValue; // ⚡ UPDATE UI INSTANTLY
    });
    widget.onToggle(newValue); // Send network request in background
  }

  void _handleSlider(double newValue) {
    setState(() {
      _localSliderValue = newValue; // ⚡ UPDATE UI INSTANTLY
    });

    // ⏳ DEBOUNCE: Wait 300ms before sending to Firebase
    // This prevents sending 50 updates while you drag across the screen
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (widget.onSliderChanged != null) {
        widget.onSliderChanged!(newValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: !widget.isAvailable ? Border.all(color: Colors.red.shade100) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isAvailable ? widget.color.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.isAvailable ? widget.color : Colors.grey, size: 28),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(
                      widget.isAvailable ? widget.subtitle : "Offline",
                      style: GoogleFonts.poppins(fontSize: 11, color: widget.isAvailable ? Colors.grey[600] : Colors.red),
                    ),
                  ],
                ),
              ),

              Switch(
                value: widget.isAvailable && _localValue, // Use Local State
                onChanged: widget.isAvailable ? _handleToggle : null,
                activeColor: widget.color,
              ),
            ],
          ),

          if (widget.isAvailable && _localSliderValue != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.tune, size: 16, color: Colors.grey[400]),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _localSliderValue!, // Use Local State
                      min: 0,
                      max: 100,
                      activeColor: widget.color,
                      inactiveColor: widget.color.withOpacity(0.1),
                      onChanged: _localValue ? _handleSlider : null, // Disable if toggle is OFF
                    ),
                  ),
                ),
                SizedBox(
                  width: 35,
                  child: Text(
                    "${_localSliderValue!.toInt()}%",
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: widget.color),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}