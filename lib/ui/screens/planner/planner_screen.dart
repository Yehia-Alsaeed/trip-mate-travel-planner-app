import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/trips_vm.dart';
import '../../../viewmodels/discover_vm.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../../data/models/trip.dart';
import '../../components/trip_card.dart';
import '../trip_details/trip_details_screen.dart';
import '../../components/place_card.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';
import '../create_trip/create_trip_screen.dart';
import 'day_planner_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthViewModel>();
      final tripsVm = context.read<TripsViewModel>();
      final discoverVm = context.read<DiscoverViewModel>();

      if (authVm.userId != null) {
        tripsVm.loadTrips(authVm.userId!);
        discoverVm.loadRecommendedPlaces(limit: 10);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Planner')),
      body: Consumer3<AuthViewModel, TripsViewModel, DiscoverViewModel>(
        builder: (context, authVm, tripsVm, discoverVm, _) {
          if (authVm.userId == null) {
            return const Center(child: Text('Please login'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await tripsVm.loadTrips(authVm.userId!);
              await discoverVm.loadRecommendedPlaces(limit: 10);
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My Trips Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Trips', style: AppTextStyles.heading2),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateTripScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Plan'),
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
                                    'No trips yet',
                                    style: AppTextStyles.heading3,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Create a new trip to start planning',
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

                      // Sort trips by nearest start date (closest to today first)
                      final now = DateTime.now();
                      final sortedTrips = List<Trip>.from(tripsVm.trips)
                        ..sort((a, b) {
                          final aDiff =
                              (a.startDate.difference(now)).abs().inDays;
                          final bDiff =
                              (b.startDate.difference(now)).abs().inDays;
                          return aDiff.compareTo(bDiff);
                        });

                      return Column(
                        children:
                            sortedTrips.map<TripCard>((trip) {
                              return TripCard(
                                trip: trip,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => TripDetailsScreen(trip: trip),
                                    ),
                                  );
                                },
                                onViewPlanner: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              DayPlannerScreen(tripId: trip.id),
                                    ),
                                  );
                                },
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => CreateTripScreen(
                                            tripToEdit: trip,
                                          ),
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
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true && mounted) {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final success = await tripsVm.deleteTrip(
                                      trip.id,
                                      authVm.userId!,
                                    );
                                    if (!mounted) return;
                                    if (success) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Trip deleted successfully',
                                          ),
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
                            }).toList(),
                      );
                    },
                  ),

                  // Recommended Destinations
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommended Destinations',
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: 16),
                        if (discoverVm.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (discoverVm.recommendedPlaces.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No recommendations available'),
                          )
                        else
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: discoverVm.recommendedPlaces.length,
                              itemBuilder: (context, index) {
                                final place =
                                    discoverVm.recommendedPlaces[index];
                                return PlaceCard(
                                  place: place,
                                  width: 160,
                                  onTap: () {
                                    // Navigate to place details
                                  },
                                );
                              },
                            ),
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
