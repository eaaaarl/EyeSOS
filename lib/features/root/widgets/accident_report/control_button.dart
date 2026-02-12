import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Color? color;
  final Color? iconColor;
  final bool? isLoading;

  const ControlButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.color,
    this.iconColor,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: isLoading == true ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: isLoading == true ? '' : tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: isLoading == true
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor ?? Theme.of(context).iconTheme.color,
                    ),
                  )
                : Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}
