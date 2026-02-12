import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LegendCard extends StatelessWidget {
  final VoidCallback onClose;
  const LegendCard({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 110,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Risk Level',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: Colors.red,
              label: 'High Risk',
              value: '80-100%',
              percentage: '80-100%',
            ),
            const SizedBox(height: 6),
            _LegendItem(
              color: Colors.yellow,
              label: 'Medium Risk',
              value: '50-80%',
              percentage: '50-80%',
            ),
            const SizedBox(height: 6),
            _LegendItem(
              color: Colors.blue,
              label: 'Low Risk',
              value: '20-50%',
              percentage: '20-50%',
            ),
            const SizedBox(height: 10),
            _LegendItem(
              color: Colors.blue,
              label: 'Your Location',
              value: '',
              icon: Icons.circle,
              percentage: '',
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: -0.2),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final IconData? icon;
  final String percentage;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.icon,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: icon != null ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: icon != null ? Border.all(color: color, width: 2) : null,
          ),
          child: icon != null ? Icon(icon, color: color, size: 10) : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (percentage.isNotEmpty)
              Text(
                percentage,
                style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[500]),
              ),
          ],
        ),
      ],
    );
  }
}
