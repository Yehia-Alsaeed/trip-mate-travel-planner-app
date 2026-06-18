import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/trip.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onViewPlanner;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;

  const TripCard({
    super.key,
    required this.trip,
    this.onViewPlanner,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompact = false,
  });

  String _formatDateRange() {
    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, yyyy');
    return '${startFormat.format(trip.startDate)} - ${endFormat.format(trip.endDate)}';
  }

  String _getDaysUntilTrip() {
    final now = DateTime.now();
    final daysUntil = trip.startDate.difference(now).inDays;
    if (daysUntil < 0) return 'Trip has passed';
    if (daysUntil == 0) return 'You leave today';
    if (daysUntil == 1) return 'You leave tomorrow';
    return 'You leave in $daysUntil days';
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit'),
                    onTap: () {
                      Navigator.pop(context);
                      onEdit!();
                    },
                  ),
                if (onDelete != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete!();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with menu button overlay
            Stack(
              children: [
                Container(
                  height: isCompact ? 120 : 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: _getTripImage(),
                ),
                if (onEdit != null || onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showMenu(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.city}, ${trip.country}',
                    style:
                        isCompact
                            ? AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            )
                            : AppTextStyles.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateRange(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: isCompact ? 12 : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDaysUntilTrip(),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: isCompact ? 11 : null,
                    ),
                  ),
                  if (onViewPlanner != null) ...[
                    SizedBox(height: isCompact ? 8 : 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onViewPlanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isCompact ? 8 : 12,
                          ),
                        ),
                        child: Text(
                          'View Planner',
                          style: TextStyle(fontSize: isCompact ? 12 : 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTripImage() {
    // Check if this is a Cairo trip and use the pyramids image
    if (trip.city.toLowerCase() == 'cairo' &&
        trip.country.toLowerCase() == 'egypt') {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.asset(
          'assets/images/cairo_pyramids.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primary.withOpacity(0.3),
              child: const Icon(
                Icons.image,
                size: 64,
                color: AppColors.primary,
              ),
            );
          },
        ),
      );
    }

    // Check if this is a Riyadh trip and use the Kingdom Centre image
    if (trip.city.toLowerCase() == 'riyadh' &&
        trip.country.toLowerCase() == 'saudi arabia') {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Image.asset(
          'assets/images/riyadh_kingdom_centre.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.primary.withOpacity(0.3),
              child: const Icon(
                Icons.image,
                size: 64,
                color: AppColors.primary,
              ),
            );
          },
        ),
      );
    }

    // Default placeholder for other trips
    return const Icon(Icons.image, size: 64, color: AppColors.primary);
  }
}
