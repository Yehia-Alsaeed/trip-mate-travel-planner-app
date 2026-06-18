import 'package:flutter/material.dart';
import '../../data/models/place.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final VoidCallback? onMenuTap;
  final bool showMenu;

  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.width,
    this.height,
    this.onMenuTap,
    this.showMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Place image or placeholder with menu button
              Expanded(
                child: Stack(
                  children: [
                    // Always use placeholder (photos removed)
                    _buildPlaceholderImage(place),
                    // Menu button overlay (top right)
                    if (showMenu && onMenuTap != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed: onMenuTap,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(Place place) {
    // Use simple icon placeholder instead of network images
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(place.category),
          size: 64,
          color: AppColors.primary.withOpacity(0.6),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'nature':
        return Icons.park;
      case 'ancient':
        return Icons.temple_buddhist;
      case 'medical':
        return Icons.local_hospital;
      default:
        return Icons.place;
    }
  }
}
