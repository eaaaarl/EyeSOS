import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Color? color;
  final Color? iconColor;
  const ControlButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}
