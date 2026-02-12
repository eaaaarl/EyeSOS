import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TopBar extends StatelessWidget {
  final String selectedMapStyle;
  final Function(String) onMapStyleChanged;
  const TopBar({
    super.key,
    required this.selectedMapStyle,
    required this.onMapStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hazard Map',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Lianga, Surigao del Sur',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Map Style Toggle
                _BuildMapStyle(
                  selectedMapStyle: selectedMapStyle,
                  onMapStyleChanged: onMapStyleChanged,
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(),
    );
  }
}

class _BuildMapStyle extends StatelessWidget {
  final String selectedMapStyle;
  final Function(String) onMapStyleChanged;

  const _BuildMapStyle({
    required this.selectedMapStyle,
    required this.onMapStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        initialValue: selectedMapStyle,
        onSelected: onMapStyleChanged,
        icon: Icon(Icons.layers, color: Colors.red[700], size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'standard',
            child: Row(
              children: [
                Icon(
                  Icons.map,
                  size: 18,
                  color: selectedMapStyle == 'standard'
                      ? Colors.red[700]
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Standard',
                  style: TextStyle(
                    color: selectedMapStyle == 'standard'
                        ? Colors.red[700]
                        : Colors.black,
                    fontWeight: selectedMapStyle == 'standard'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'satellite',
            child: Row(
              children: [
                Icon(
                  Icons.satellite_alt,
                  size: 18,
                  color: selectedMapStyle == 'satellite'
                      ? Colors.red[700]
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Satellite',
                  style: TextStyle(
                    color: selectedMapStyle == 'satellite'
                        ? Colors.red[700]
                        : Colors.black,
                    fontWeight: selectedMapStyle == 'satellite'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
