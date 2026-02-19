import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickStatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const QuickStatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Fixed height for consistency
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2, // Allow 2 lines max
            overflow: TextOverflow.ellipsis, // Add ellipsis if too long
            style: GoogleFonts.inter(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w500,
              height: 1.2, // Tighter line height
            ),
          ),
        ],
      ),
    );
  }
}
