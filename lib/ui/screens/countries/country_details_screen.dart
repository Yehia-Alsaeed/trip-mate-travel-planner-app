import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/country.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';
import '../create_trip/create_trip_screen.dart';

class CountryDetailsScreen extends StatelessWidget {
  final Country country;

  const CountryDetailsScreen({super.key, required this.country});

  Future<void> _openGoogleMaps() async {
    if (country.googleMapsUrl.isEmpty) {
      return;
    }

    final uri = Uri.parse(country.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with flag
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  country.flagPng.isNotEmpty
                      ? Image.network(
                        country.flagPng,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primary.withOpacity(0.3),
                            child: const Icon(
                              Icons.flag,
                              size: 64,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: AppColors.primary.withOpacity(0.3),
                        child: const Icon(
                          Icons.flag,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country name
                  Text(country.nameCommon, style: AppTextStyles.heading2),
                  const SizedBox(height: 4),
                  Text(
                    country.nameOfficial,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Capital
                  _buildSectionTitle('Capital'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_city,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              country.capitalText,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Region & Subregion
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.public, 'Region', country.region),
                          const Divider(),
                          _buildInfoRow(
                            Icons.map,
                            'Subregion',
                            country.subregion,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Population
                  _buildSectionTitle('Population'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  country.formattedPopulation,
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${country.population.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} people',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Languages
                  if (country.languages.isNotEmpty) ...[
                    _buildSectionTitle('Languages'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          country.languages.entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.2,
                              ),
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Currencies
                  if (country.currencies.isNotEmpty) ...[
                    _buildSectionTitle('Currencies'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          country.currencies.entries.map((entry) {
                            return Chip(
                              label: Text(
                                '${entry.key}${entry.value.symbol.isNotEmpty ? ' (${entry.value.symbol})' : ''}',
                              ),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.2,
                              ),
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Create a new plan button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateTripScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create a new plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Google Maps button
                  if (country.googleMapsUrl.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openGoogleMaps,
                        icon: const Icon(Icons.map),
                        label: const Text('Open in Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.heading3);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
