import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  final bool isLoading;
  final VoidCallback onTap;

  const ReportItemCard({
    super.key,
    required this.id,
    required this.title,
    required this.reportNumber,
    required this.location,
    required this.time,
    required this.notes,
    required this.imageUrl,
    required this.imageCount,
    required this.onTap,
    required this.isLast,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image (skeleton or actual)
                if (isLoading)
                  Bone.square(size: 80, borderRadius: BorderRadius.circular(8))
                else if (imageUrl.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: _buildImageWithSkeleton(imageUrl, imageCount),
                  ),

                if (!isLoading && imageUrl.isNotEmpty)
                  const SizedBox(width: 0)
                else if (isLoading)
                  const SizedBox(width: 14),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Severity Badge Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and ID
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isLoading)
                                    Bone(width: 100, height: 16)
                                  else
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                        height: 1.2,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (isLoading)
                                    Bone(width: 120, height: 12)
                                  else
                                    Text(
                                      'ID: $reportNumber',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        height: 1.33,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading)
                            Bone.square(size: 14)
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: isLoading
                                ? Bone(width: 150, height: 12)
                                : Text(
                                    location,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      height: 1.33,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),

                      // Notes (if available or loading)
                      if (isLoading ||
                          (notes != null && notes!.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        if (isLoading)
                          Bone(width: 200, height: 14)
                        else
                          Text(
                            notes!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],

                      const SizedBox(height: 8),

                      // Time and "Tap to view" Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Time
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLoading)
                                  Bone.square(size: 13)
                                else
                                  Icon(
                                    Icons.access_time,
                                    size: 13,
                                    color: Colors.grey[400],
                                  ),
                                const SizedBox(width: 4),
                                if (isLoading)
                                  Bone(width: 50, height: 12)
                                else
                                  Text(
                                    time,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Tap to view
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading)
                                Bone(width: 50, height: 12)
                              else
                                Text(
                                  'Tap to view',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              const SizedBox(width: 4),
                              if (isLoading)
                                Bone.square(size: 14)
                              else
                                Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                            ],
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
}

Widget _buildImageWithSkeleton(String imageUrl, int count) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmerPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
        ),
      ),
      if (count > 1) _buildCountOverlay(count),
    ],
  );
}

Widget _buildShimmerPlaceholder() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

Widget _buildErrorWidget() {
  return Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
  );
}

Widget _buildCountOverlay(int count) {
  return Positioned(
    top: 4,
    right: 4,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '+${count - 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
