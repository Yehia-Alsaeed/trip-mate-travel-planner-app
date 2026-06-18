import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/discover_vm.dart';
import '../../../data/constants/geoapify_category_map.dart';
import '../../components/place_card.dart';
import '../../components/app_colors.dart';
import '../place_details/place_details_screen.dart';

class DiscoverPlacesScreen extends StatefulWidget {
  const DiscoverPlacesScreen({super.key});

  @override
  State<DiscoverPlacesScreen> createState() => _DiscoverPlacesScreenState();
}

class _DiscoverPlacesScreenState extends State<DiscoverPlacesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('DiscoverPlacesScreen: initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'DiscoverPlacesScreen: PostFrameCallback - initializing and loading places',
      );
      final discoverVm = context.read<DiscoverViewModel>();
      // Auto-load places with default category
      discoverVm.init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Truncate error message to prevent UI overflow
  String _truncateError(String error) {
    if (error.length <= 200) return error;
    return '${error.substring(0, 197)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Places')),
      body: Consumer<DiscoverViewModel>(
        builder: (context, discoverVm, _) {
          return Column(
            children: [
              // Category chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        GeoapifyCategoryMap.getAvailableCategories().map((
                          category,
                        ) {
                          final isSelected =
                              discoverVm.selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  discoverVm.setCategory(category);
                                }
                              },
                              selectedColor: AppColors.primary.withOpacity(0.3),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : Colors.black87,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Discover Places..',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                discoverVm.setSearchQuery('');
                                discoverVm.loadNearbyPlaces();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    discoverVm.setSearchQuery(value);
                    if (value.isNotEmpty) {
                      discoverVm.searchPlaces(value);
                    } else {
                      // Clear search and reload nearby places with current category
                      discoverVm.loadNearbyPlaces();
                    }
                  },
                  onSubmitted: (value) {
                    discoverVm.searchPlaces(value);
                  },
                ),
              ),

              // Error message - truncated to prevent overflow
              if (discoverVm.errorMessage != null && !discoverVm.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _truncateError(discoverVm.errorMessage!),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                discoverVm.clearError();
                                discoverVm.loadNearbyPlaces();
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Content
              Expanded(
                child:
                    discoverVm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : discoverVm.places.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text('No places found'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  discoverVm.loadNearbyPlaces();
                                },
                                child: const Text('Reload'),
                              ),
                            ],
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: discoverVm.places.length,
                          itemBuilder: (context, index) {
                            final place = discoverVm.places[index];
                            return PlaceCard(
                              place: place,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PlaceDetailsScreen(place: place),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
