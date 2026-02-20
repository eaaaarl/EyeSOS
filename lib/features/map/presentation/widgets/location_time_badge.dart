import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eyesos/features/map/bloc/location_state.dart';

class LocationTimeBadge extends StatelessWidget {
  final LocationState locationState;

  const LocationTimeBadge({super.key, required this.locationState});

  @override
  Widget build(BuildContext context) {
    if (locationState is! LocationLoaded) return const SizedBox.shrink();

    final state = locationState as LocationLoaded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 11, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            _getTimeAgo(state.timestamp),
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 10) {
      return 'now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
