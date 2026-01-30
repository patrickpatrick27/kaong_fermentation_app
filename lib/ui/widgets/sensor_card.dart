import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/history_screen.dart'; 

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String machineId; 
  final String dbKey;     

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.machineId,
    required this.dbKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => 
              HistoryScreen(
                machineId: machineId, 
                sensorName: title, 
                sensorKey: dbKey, 
                unit: unit, 
                themeColor: color
              )
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                
                // Value and Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold, 
                            color: color
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: GoogleFonts.poppins(
                            fontSize: 14, 
                            color: Colors.grey
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12, 
                        color: Colors.grey[600]
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}