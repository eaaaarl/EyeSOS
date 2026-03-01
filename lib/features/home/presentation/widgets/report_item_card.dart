import 'package:cached_network_image/cached_network_image.dart';
import 'package:eyesos/features/home/domain/entities/accident_status_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago_lib;

class ReportItemCard extends StatelessWidget {
  final String id;
  final bool isLast;
  final String title;
  final String reportNumber;
  final String location;
  final String time;
  final String? notes;
  final String imageUrl;
  final int imageCount;
  final String? severity;
  final AccidentStatus? accidentStatus;
  final DateTime? updatedAt;
  final bool isLoading;
  final VoidCallback onTap;

  const ReportItemCard({
    super.key,
    required this.id,
    required this.title,
    required this.reportNumber,
    required this.location,
    required this.time,
    this.notes,
    required this.imageUrl,
    required this.imageCount,
    required this.onTap,
    required this.isLast,
    this.severity,
    this.accidentStatus,
    this.updatedAt,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Image Section
                if (isLoading)
                  Bone.square(size: 90, borderRadius: BorderRadius.circular(16))
                else if (imageUrl.isNotEmpty)
                  _buildPremiumImage(imageUrl, imageCount)
                else
                  _buildNoImagePlaceholder(),

                const SizedBox(width: 18),

                // Content Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Severity Badges Row
                      Row(
                        children: [
                          if (severity != null &&
                              !isLoading &&
                              severity!.isNotEmpty)
                            _buildSeverityBadge(severity!),
                          if (severity != null &&
                              severity!.isNotEmpty &&
                              accidentStatus != null &&
                              !isLoading)
                            const SizedBox(width: 8),
                          if (accidentStatus != null && !isLoading)
                            _buildStatusBadge(accidentStatus!),
                          if (isLoading)
                            Bone(
                              width: 60,
                              height: 20,
                              borderRadius: BorderRadius.circular(6),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title and ID
                      if (isLoading)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone(width: 140, height: 20),
                            const SizedBox(height: 6),
                            Bone(width: 100, height: 14),
                          ],
                        )
                      else ...[
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $reportNumber',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: isLoading
                                ? Bone(width: 180, height: 14)
                                : Text(
                                    location,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),

                      if (notes != null && notes!.isNotEmpty && !isLoading) ...[
                        const SizedBox(height: 8),
                        Text(
                          notes!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Footer: Time and "View"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (updatedAt != null && !isLoading) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Updated ${timeago_lib.format(updatedAt!)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.blue[400],
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'View',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: Colors.grey[700],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumImage(String imageUrl, int count) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildShimmerPlaceholder(),
              errorWidget: (context, url, error) => _buildErrorWidget(),
            ),
          ),
        ),
        if (count > 1) _buildCountOverlay(count),
      ],
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 24,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.grey[300],
        size: 24,
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            severity.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AccidentStatus status) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            status.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    final cleanSeverity = severity.toLowerCase().trim();
    switch (cleanSeverity) {
      case 'emergency':
        return Colors.red[900]!;
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'moderate':
      case 'medium':
        return Colors.yellow[800]!;
      case 'minor':
      case 'low':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildCountOverlay(int count) {
    return Positioned(
      bottom: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '+${count - 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
