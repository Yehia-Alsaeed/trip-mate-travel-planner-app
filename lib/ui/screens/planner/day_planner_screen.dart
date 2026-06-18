import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/planner_vm.dart';
import '../../../viewmodels/trips_vm.dart';
import '../../../viewmodels/discover_vm.dart';
import '../../../data/models/planner_item.dart';
import '../../../data/models/place.dart';
import '../../../data/models/trip.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';
import '../discover/discover_places_screen.dart';
import '../place_details/place_details_screen.dart';

class DayPlannerScreen extends StatefulWidget {
  final String tripId;

  const DayPlannerScreen({super.key, required this.tripId});

  @override
  State<DayPlannerScreen> createState() => _DayPlannerScreenState();
}

class _DayPlannerScreenState extends State<DayPlannerScreen> {
  Map<String, Place?> _placeCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plannerVm = context.read<PlannerViewModel>();
      plannerVm.loadPlannerItems(widget.tripId);
      _loadPlaceDetails(plannerVm);
    });
  }

  Future<void> _loadPlaceDetails(PlannerViewModel plannerVm) async {
    final discoverVm = context.read<DiscoverViewModel>();
    final placeIds = plannerVm.plannerItems.map((item) => item.placeId).toSet();

    for (final placeId in placeIds) {
      if (!_placeCache.containsKey(placeId)) {
        final place = await discoverVm.getPlaceById(placeId);
        if (mounted) {
          setState(() {
            _placeCache[placeId] = place;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsVm = context.watch<TripsViewModel>();
    final trips = tripsVm.trips;
    final trip =
        trips.isNotEmpty
            ? trips.firstWhere(
              (t) => t.id == widget.tripId,
              orElse: () => tripsVm.currentTrip ?? trips.first,
            )
            : tripsVm.currentTrip;

    if (trip == null) {
      return const Scaffold(body: Center(child: Text('Trip not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${trip.city} Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiscoverPlacesScreen()),
              );
            },
            tooltip: 'Add Place',
          ),
        ],
      ),
      body: Consumer<PlannerViewModel>(
        builder: (context, plannerVm, _) {
          if (plannerVm.isLoading && plannerVm.plannerItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final itemsByDate = plannerVm.getItemsByDate();

          // Reload place details when items change
          if (plannerVm.plannerItems.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadPlaceDetails(plannerVm);
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              await plannerVm.loadPlannerItems(widget.tripId);
              await _loadPlaceDetails(plannerVm);
            },
            child:
                itemsByDate.isEmpty
                    ? _buildEmptyState(trip)
                    : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Trip Overview Card
                        _buildTripOverviewCard(trip, plannerVm),
                        const SizedBox(height: 16),
                        // Planner Items by Date
                        ...itemsByDate.entries.map((entry) {
                          return _buildDayCard(entry.key, entry.value);
                        }),
                      ],
                    ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(trip) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text('No items planned yet', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            const Text(
              'Add places to your planner',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DiscoverPlacesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore),
              label: const Text('Discover Places'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Suggested Places in ${trip.city}',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _buildSuggestedPlaces(trip),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaces(trip) {
    final plannerVm = context.read<PlannerViewModel>();

    // Get suggested places based on trip city and interests
    final suggestions = _getSuggestedPlacesForTrip(trip);

    if (suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No suggestions available for this trip'),
      );
    }

    return Column(
      children:
          suggestions.map((placeData) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.place, color: AppColors.primary),
                title: Text(placeData['name']!),
                subtitle: Text(
                  '${placeData['category']} • ${placeData['time']} • ${placeData['duration']} hours',
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () async {
                    await _addSuggestedPlace(
                      plannerVm,
                      trip,
                      placeData['placeId']!,
                      placeData['time']!,
                      placeData['duration']!,
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  List<Map<String, dynamic>> _getSuggestedPlacesForTrip(trip) {
    final city = trip.city.toLowerCase();
    final country = trip.country.toLowerCase();
    final interests = trip.interests.map((i) => i.toLowerCase()).toList();

    // Cairo, Egypt suggestions
    if (city == 'cairo' && country == 'egypt') {
      return [
        {
          'name': 'Giza Pyramids',
          'category': 'Ancient',
          'time': '9:00 AM',
          'duration': 3,
          'placeId': 'place_giza_pyramids',
        },
        {
          'name': 'Grand Egyptian Museum',
          'category': 'Ancient',
          'time': '2:00 PM',
          'duration': 2,
          'placeId': 'place_1',
        },
        {
          'name': 'Khan el-Khalili',
          'category': 'Shopping',
          'time': '5:00 PM',
          'duration': 2,
          'placeId': 'place_3',
        },
        {
          'name': 'Salah Eldin Citadel',
          'category': 'Ancient',
          'time': '9:00 AM',
          'duration': 2,
          'placeId': 'place_2',
        },
      ];
    }

    // Dubai suggestions
    if (city == 'dubai') {
      return [
        {
          'name': 'Museum of the Future',
          'category': 'Nature',
          'time': '10:00 AM',
          'duration': 2,
          'placeId': 'place_4',
        },
      ];
    }

    // Tokyo suggestions
    if (city == 'tokyo') {
      return [
        {
          'name': 'Shibuya Crossing',
          'category': 'Shopping',
          'time': '11:00 AM',
          'duration': 1,
          'placeId': 'place_5',
        },
      ];
    }

    // Generic suggestions based on interests
    final genericSuggestions = <Map<String, dynamic>>[];
    if (interests.contains('ancient')) {
      genericSuggestions.add({
        'name': 'Historical Site',
        'category': 'Ancient',
        'time': '10:00 AM',
        'duration': 2,
        'placeId': 'place_ancient_1',
      });
    }
    if (interests.contains('food')) {
      genericSuggestions.add({
        'name': 'Local Restaurant',
        'category': 'Food',
        'time': '12:00 PM',
        'duration': 1,
        'placeId': 'place_food_1',
      });
    }
    if (interests.contains('shopping')) {
      genericSuggestions.add({
        'name': 'Shopping District',
        'category': 'Shopping',
        'time': '3:00 PM',
        'duration': 2,
        'placeId': 'place_shopping_1',
      });
    }
    if (interests.contains('nature')) {
      genericSuggestions.add({
        'name': 'Nature Park',
        'category': 'Nature',
        'time': '9:00 AM',
        'duration': 3,
        'placeId': 'place_nature_1',
      });
    }

    return genericSuggestions;
  }

  Future<void> _addSuggestedPlace(
    PlannerViewModel plannerVm,
    Trip trip,
    String placeId,
    String timeStr,
    int durationHours,
  ) async {
    // Parse time string (e.g., "9:00 AM" or "2:00 PM")
    final isPM = timeStr.contains('PM');
    final timeParts = timeStr
        .replaceAll(' AM', '')
        .replaceAll(' PM', '')
        .split(':');
    int hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

    // Convert to 24-hour format
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    // Use first day of trip for suggested places
    final date = trip.startDate;
    final startTime = TimeOfDay(hour: hour, minute: minute);
    final duration = Duration(hours: durationHours);

    final success = await plannerVm.addPlannerItem(
      tripId: trip.id,
      placeId: placeId,
      date: date,
      startTime: startTime,
      duration: duration,
    );

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      if (success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Place added to planner successfully')),
        );
        // Reload planner items and place details
        await plannerVm.loadPlannerItems(trip.id);
        _loadPlaceDetails(plannerVm);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              plannerVm.errorMessage ?? 'Failed to add place to planner',
            ),
          ),
        );
      }
    }
  }

  Widget _buildTripOverviewCard(trip, plannerVm) {
    final tripDuration = trip.endDate.difference(trip.startDate).inDays + 1;
    final totalItems = plannerVm.plannerItems.length;
    final uniqueDates = plannerVm.getItemsByDate().keys.length;

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip.city}, ${trip.country}',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM d').format(trip.startDate)} - ${DateFormat('MMM d, yyyy').format(trip.endDate)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.event, '$tripDuration', 'Days'),
                _buildStatItem(Icons.location_on, '$totalItems', 'Places'),
                _buildStatItem(
                  Icons.calendar_view_week,
                  '$uniqueDates',
                  'Days Planned',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildDayCard(DateTime date, List<PlannerItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(date),
                    style: AppTextStyles.heading3,
                  ),
                ),
                Chip(
                  label: Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildPlannerItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannerItem(PlannerItem item) {
    // Use stored Place object from PlannerItem, fallback to cache, then to placeId
    final place = item.place ?? _placeCache[item.placeId];
    final startTime =
        '${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')}';
    final endTime = item.endTime;
    final endTimeStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final durationHours = item.duration.inHours;
    final durationMinutes = item.duration.inMinutes % 60;
    final durationText =
        durationHours > 0
            ? '${durationHours}h ${durationMinutes > 0 ? '${durationMinutes}m' : ''}'
            : '${durationMinutes}m';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap:
            place != null
                ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailsScreen(place: place),
                    ),
                  );
                }
                : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Time indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Time info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startTime,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    endTimeStr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(durationText, style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(width: 12),
              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place?.name ?? 'Unknown Place',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place?.category != null) ...[
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(place!.category),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete Item'),
                          content: const Text(
                            'Are you sure you want to delete this item?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                  );

                  if (confirmed == true && mounted) {
                    final plannerVm = context.read<PlannerViewModel>();
                    await plannerVm.deletePlannerItem(item.id);
                    if (mounted) {
                      final messenger = ScaffoldMessenger.of(context);
                      if (plannerVm.errorMessage != null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(plannerVm.errorMessage!)),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Item deleted successfully'),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
