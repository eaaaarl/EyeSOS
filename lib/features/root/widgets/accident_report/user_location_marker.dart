import 'package:flutter/material.dart';

class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_pin_circle,
      color: Colors.red[700],
      size: 40,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
