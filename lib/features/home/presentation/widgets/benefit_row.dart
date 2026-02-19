import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const BenefitRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.red[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
      ],
    );
  }
}
