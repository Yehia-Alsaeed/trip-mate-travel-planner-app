import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/discover_vm.dart';
import '../../../data/models/place.dart';
import '../../components/place_card.dart';
import '../../components/chips_row.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';

class CityExploreScreen extends StatefulWidget {
  final String? city;
  final String? country;

  const CityExploreScreen({super.key, this.city, this.country});

  @override
  State<CityExploreScreen> createState() => _CityExploreScreenState();
}

class _CityExploreScreenState extends State<CityExploreScreen> {
  final _searchController = TextEditingController();
  List<String> _cityChips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discoverVm = context.read<DiscoverViewModel>();
      if (widget.city != null) {
        discoverVm.setSelectedCity(widget.city);
        discoverVm.loadPlacesByCity(widget.city!);
      }
      if (widget.country != null) {
        discoverVm.getCitiesByCountry(widget.country!).then((cities) {
          setState(() {
            _cityChips = cities;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City Explore')),
      body: Consumer<DiscoverViewModel>(
        builder: (context, discoverVm, _) {
          return Column(
            children: [
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
                                discoverVm.searchPlaces('');
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
                    }
                  },
                  onSubmitted: (value) {
                    discoverVm.searchPlaces(value);
                  },
                ),
              ),

              // Featured city section
              if (widget.city != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large city image placeholder
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.city}, ${widget.country ?? ""}',
                        style: AppTextStyles.heading2,
                      ),
                    ],
                  ),
                ),

              // Other cities section
              if (_cityChips.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Other cities in this country',
                    style: AppTextStyles.heading3,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cityChips.length > 2 ? 2 : _cityChips.length,
                    itemBuilder: (context, index) {
                      return PlaceCard(
                        place: Place(
                          id: 'city_${_cityChips[index]}',
                          name: _cityChips[index],
                          category: 'City',
                        ),
                        width: 150,
                        height: 150,
                        onTap: () {
                          discoverVm.loadPlacesByCity(_cityChips[index]);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // City filter chips
              if (_cityChips.isNotEmpty)
                ChipsRow(
                  chips: _cityChips,
                  selectedChip: discoverVm.selectedCity,
                  onChipSelected: (city) {
                    discoverVm.loadPlacesByCity(city);
                  },
                ),
              const SizedBox(height: 16),

              // Places list
              Expanded(
                child:
                    discoverVm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : discoverVm.places.isEmpty
                        ? const Center(child: Text('No places found'))
                        : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: discoverVm.places.length,
                          itemBuilder: (context, index) {
                            return PlaceCard(
                              place: discoverVm.places[index],
                              onTap: () {
                                // Navigate to place details
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
