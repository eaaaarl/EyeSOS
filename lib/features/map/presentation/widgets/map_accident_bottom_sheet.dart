import 'package:cached_network_image/cached_network_image.dart';
import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class MapAccidentBottomSheet extends StatefulWidget {
  final AccidentEntity accident;

  const MapAccidentBottomSheet({super.key, required this.accident});

  @override
  State<MapAccidentBottomSheet> createState() => _MapAccidentBottomSheetState();
}

class _MapAccidentBottomSheetState extends State<MapAccidentBottomSheet> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Accident Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  if (widget.accident.imageUrls.isNotEmpty) ...[
                    _buildImageGallery(),
                    const SizedBox(height: 24),
                  ],

                  // Status and Severity Badges
                  Row(
                    children: [
                      _buildBadge(
                        label: widget.accident.accidentStatus.label
                            .toUpperCase(),
                        icon: widget.accident.accidentStatus.icon,
                        color: widget.accident.accidentStatus.color,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        label:
                            '${widget.accident.severity?.toUpperCase() ?? "UNKNOWN"} SEVERITY',
                        icon: Icons.warning_amber_rounded,
                        color: widget.accident.severityColor,
                        isSeverity: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Location Section
                  _buildInfoSection(
                    icon: Icons.location_on,
                    iconColor: Colors.red[600]!,
                    title: 'Location',
                    content: widget.accident.locationAddress,
                  ),

                  const SizedBox(height: 20),

                  // Reported Time
                  _buildInfoSection(
                    icon: Icons.access_time,
                    iconColor: Colors.blue[600]!,
                    title: 'Reported',
                    content: timeago.format(widget.accident.createdAt),
                    subtitle: _formatDateTime(widget.accident.createdAt),
                  ),

                  if (widget.accident.accidentStatus.label.toLowerCase() ==
                          'resolved' &&
                      widget.accident.updatedAt != null) ...[
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      icon: Icons.check_circle,
                      iconColor: Colors.green[600]!,
                      title: 'Resolved Time',
                      content: timeago.format(widget.accident.updatedAt!),
                      subtitle: _formatDateTime(widget.accident.updatedAt!),
                    ),
                  ],

                  if (widget.accident.reporterNotes != null &&
                      widget.accident.reporterNotes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      icon: Icons.description,
                      iconColor: Colors.orange[600]!,
                      title: 'Reporter Notes',
                      content: widget.accident.reporterNotes!,
                    ),
                  ],

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: widget.accident.imageUrls.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.accident.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildImagePlaceholder(),
                  errorWidget: (context, url, error) => _buildImageError(),
                );
              },
            ),
          ),
        ),
        if (widget.accident.imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.accident.imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentImageIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentImageIndex
                      ? Colors.red[700]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
    bool isSeverity = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month $day, $year at $hour:$minute';
  }
}
