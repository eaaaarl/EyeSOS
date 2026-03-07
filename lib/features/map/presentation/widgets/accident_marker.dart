import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:flutter/material.dart';

class AccidentMarker extends StatelessWidget {
  final AccidentEntity accident;

  const AccidentMarker({super.key, required this.accident});

  @override
  Widget build(BuildContext context) {
    final color = accident.severityColor;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          accident.isSos ? Icons.sos : Icons.location_on,
          color: color,
          size: 25,
        ),
      ),
    );
  }
}
