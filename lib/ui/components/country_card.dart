import 'package:flutter/material.dart';
import '../../data/models/country.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class CountryCard extends StatelessWidget {
  final Country country;
  final VoidCallback? onTap;
  final double? width;

  const CountryCard({super.key, required this.country, this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width ?? 140,
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flag image - takes most of the space
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child:
                    country.flagPng.isNotEmpty
                        ? Image.network(
                          country.flagPng,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 140,
                              color: AppColors.primary.withOpacity(0.2),
                              child: const Icon(
                                Icons.flag,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        )
                        : Container(
                          height: 140,
                          color: AppColors.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.flag,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
              ),
              // Country name only
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Center(
                    child: Text(
                      country.nameCommon,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
