import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/trips_vm.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../../viewmodels/planner_vm.dart';
import '../../../viewmodels/recommended_countries_vm.dart';
import '../../components/trip_card.dart';
import '../trip_details/trip_details_screen.dart';
import '../../components/tourism_type_item.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';
import '../create_trip/create_trip_screen.dart';
import '../discover/discover_places_screen.dart';
import '../planner/day_planner_screen.dart';
import '../profile/profile_screen.dart';
import '../countries/country_details_screen.dart';
import '../../components/country_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthViewModel>();
      final tripsVm = context.read<TripsViewModel>();
      final plannerVm = context.read<PlannerViewModel>();

      if (authVm.userId != null) {
        // Load user profile if not already loaded
        if (authVm.userFirstName == null) {
          authVm.loadUserProfile();
        }

        // Load data asynchronously
        (() async {
          await tripsVm.loadTrips(authVm.userId!);

          // Load recommended countries
          final recommendedCountriesVm =
              context.read<RecommendedCountriesViewModel>();
          recommendedCountriesVm.loadRecommendedCountries();

          // Load planner items for nearest trip (moved from build)
          final trips = tripsVm.trips;
          if (trips.isNotEmpty) {
            final now = DateTime.now();
            final nearestTrip = trips.reduce((a, b) {
              final aDiff = (a.startDate.difference(now)).abs().inDays;
              final bDiff = (b.startDate.difference(now)).abs().inDays;
              return aDiff < bDiff ? a : b;
            });
            if (plannerVm.selectedTripId != nearestTrip.id) {
              await plannerVm.loadPlannerItems(nearestTrip.id);
            }
          }
        })();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Mate', style: AppTextStyles.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer3<AuthViewModel, TripsViewModel, PlannerViewModel>(
        builder: (context, authVm, tripsVm, plannerVm, _) {
          if (authVm.userId == null) {
            return const Center(child: Text('Please login'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await tripsVm.loadTrips(authVm.userId!);
              // Reload planner items for current trip
              final trips = tripsVm.trips;
              if (trips.isNotEmpty) {
                final now = DateTime.now();
                final nearestTrip = trips.reduce((a, b) {
                  final aDiff = (a.startDate.difference(now)).abs().inDays;
                  final bDiff = (b.startDate.difference(now)).abs().inDays;
                  return aDiff < bDiff ? a : b;
                });
                await plannerVm.loadPlannerItems(nearestTrip.id);
              }
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personalized greeting
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Hello, ${authVm.userFirstName ?? authVm.userId?.substring(0, 5) ?? 'User'}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),

                  // Current Trip Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Trip',
                          style: AppTextStyles.heading2,
                        ),
                        TextButton.icon(
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
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      if (tripsVm.trips.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.luggage_outlined,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No current trip',
                                    style: AppTextStyles.heading3,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Create a new trip to get started',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const CreateTripScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Create Trip'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Find trip with nearest start date
                      final now = DateTime.now();
                      final trips = tripsVm.trips;
                      final nearestTrip = trips.reduce((a, b) {
                        final aDiff =
                            (a.startDate.difference(now)).abs().inDays;
                        final bDiff =
                            (b.startDate.difference(now)).abs().inDays;
                        return aDiff < bDiff ? a : b;
                      });

                      // Note: planner items are loaded in initState, not here

                      return TripCard(
                        trip: nearestTrip,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => TripDetailsScreen(trip: nearestTrip),
                            ),
                          );
                        },
                        onViewPlanner: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      DayPlannerScreen(tripId: nearestTrip.id),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      CreateTripScreen(tripToEdit: nearestTrip),
                            ),
                          );
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Trip'),
                                  content: const Text(
                                    'Are you sure you want to delete this trip? This will also delete all planner items.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true && mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await tripsVm.deleteTrip(
                              nearestTrip.id,
                              authVm.userId!,
                            );
                            if (!mounted) return;
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Trip deleted successfully'),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tripsVm.errorMessage ??
                                        'Failed to delete trip',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),

                  // Trip Overview Section (Countdown & Stats)
                  Builder(
                    builder: (context) {
                      final trips = tripsVm.trips;
                      if (trips.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final now = DateTime.now();
                      final nearestTrip = trips.reduce((a, b) {
                        final aDiff =
                            (a.startDate.difference(now)).abs().inDays;
                        final bDiff =
                            (b.startDate.difference(now)).abs().inDays;
                        return aDiff < bDiff ? a : b;
                      });

                      // Note: planner items are loaded in initState, not here

                      final daysUntilTrip =
                          nearestTrip.startDate.difference(now).inDays;
                      final tripDuration =
                          nearestTrip.endDate
                              .difference(nearestTrip.startDate)
                              .inDays +
                          1;
                      final placesCount = plannerVm.plannerItems.length;
                      final uniqueDates =
                          plannerVm.plannerItems
                              .map((item) {
                                return DateTime(
                                  item.date.year,
                                  item.date.month,
                                  item.date.day,
                                );
                              })
                              .toSet()
                              .length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trip Countdown Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              color: AppColors.primary.withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            daysUntilTrip > 0
                                                ? '$daysUntilTrip ${daysUntilTrip == 1 ? 'day' : 'days'} until trip'
                                                : daysUntilTrip == 0
                                                ? 'Trip starts today!'
                                                : 'Trip in progress',
                                            style: AppTextStyles.heading3,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${nearestTrip.city}, ${nearestTrip.country}',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick Stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.location_on,
                                    label: 'Places',
                                    value: placesCount.toString(),
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.calendar_view_week,
                                    label: 'Days Planned',
                                    value: uniqueDates.toString(),
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.access_time,
                                    label: 'Duration',
                                    value: '$tripDuration days',
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // Recommended Countries
                  Consumer<RecommendedCountriesViewModel>(
                    builder: (context, recommendedCountriesVm, _) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Recommended Countries',
                              style: AppTextStyles.heading2,
                            ),
                            const SizedBox(height: 8),
                            if (recommendedCountriesVm.isLoading)
                              const SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (recommendedCountriesVm.errorMessage !=
                                null)
                              Card(
                                color: Colors.orange.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          recommendedCountriesVm.errorMessage!,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (recommendedCountriesVm.recommended.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No countries available'),
                              )
                            else
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      recommendedCountriesVm.recommended.length,
                                  itemBuilder: (context, index) {
                                    final country =
                                        recommendedCountriesVm
                                            .recommended[index];
                                    return CountryCard(
                                      country: country,
                                      width: 140,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CountryDetailsScreen(
                                                  country: country,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Types of Tourism
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Types of Tourism',
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            TourismTypeItem(
                              type: 'Ancient',
                              icon: Icons.temple_buddhist,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const DiscoverPlacesScreen(),
                                  ),
                                );
                              },
                            ),
                            TourismTypeItem(
                              type: 'Medical',
                              icon: Icons.medical_services,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const DiscoverPlacesScreen(),
                                  ),
                                );
                              },
                            ),
                            TourismTypeItem(
                              type: 'Nature',
                              icon: Icons.nature,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const DiscoverPlacesScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
