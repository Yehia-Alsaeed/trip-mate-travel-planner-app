import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/trip.dart';
import '../../../viewmodels/planner_vm.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';
import '../planner/day_planner_screen.dart';
import '../create_trip/create_trip_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plannerVm = context.read<PlannerViewModel>();
      plannerVm.loadPlannerItems(widget.trip.id);
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  String _getDaysUntilTrip() {
    final now = DateTime.now();
    final daysUntil = widget.trip.startDate.difference(now).inDays;
    if (daysUntil < 0) return 'Trip has passed';
    if (daysUntil == 0) return 'You leave today';
    if (daysUntil == 1) return 'You leave tomorrow';
    return 'You leave in $daysUntil days';
  }

  String _getTripDuration() {
    final duration =
        widget.trip.endDate.difference(widget.trip.startDate).inDays + 1;
    return '$duration ${duration == 1 ? 'day' : 'days'}';
  }

  Widget _getTripImage() {
    // Check if this is a Cairo trip and use the pyramids image
    if (widget.trip.city.toLowerCase() == 'cairo' &&
        widget.trip.country.toLowerCase() == 'egypt') {
      return Image.asset(
        'assets/images/cairo_pyramids.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primary.withOpacity(0.3),
            child: const Icon(Icons.image, size: 64, color: AppColors.primary),
          );
        },
      );
    }

    // Check if this is a Riyadh trip and use the Kingdom Centre image
    if (widget.trip.city.toLowerCase() == 'riyadh' &&
        widget.trip.country.toLowerCase() == 'saudi arabia') {
      return Image.asset(
        'assets/images/riyadh_kingdom_centre.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.primary.withOpacity(0.3),
            child: const Icon(Icons.image, size: 64, color: AppColors.primary),
          );
        },
      );
    }

    // Default placeholder for other trips
    return Container(
      color: AppColors.primary.withOpacity(0.3),
      child: const Icon(Icons.image, size: 64, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plannerVm = context.watch<PlannerViewModel>();

    // Get planner items for stats
    final plannerItems =
        plannerVm.plannerItems
            .where((item) => item.tripId == widget.trip.id)
            .toList();
    final itemsByDate = plannerVm.getItemsByDate();
    final uniqueDates =
        itemsByDate.keys
            .where(
              (date) => plannerItems.any(
                (item) =>
                    item.date.year == date.year &&
                    item.date.month == date.month &&
                    item.date.day == date.day,
              ),
            )
            .length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(background: _getTripImage()),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTripScreen(tripToEdit: widget.trip),
                    ),
                  );
                },
                tooltip: 'Edit Trip',
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip name and location
                  Text(
                    '${widget.trip.city}, ${widget.trip.country}',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDaysUntilTrip(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Stats - using white background for better visibility
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.calendar_today,
                            _getTripDuration(),
                            'Duration',
                          ),
                          _buildStatItem(
                            Icons.attach_money,
                            '\$${widget.trip.budget.toStringAsFixed(0)}',
                            'Budget',
                          ),
                          _buildStatItem(
                            Icons.location_on,
                            '${plannerItems.length}',
                            'Places',
                          ),
                          _buildStatItem(
                            Icons.event,
                            '$uniqueDates',
                            'Days Planned',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dates
                  _buildSectionTitle('Dates'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.flight_takeoff,
                            'Start Date',
                            _formatDate(widget.trip.startDate),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.flight_land,
                            'End Date',
                            _formatDate(widget.trip.endDate),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interests
                  _buildSectionTitle('Interests'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        widget.trip.interests.map((interest) {
                          return Chip(
                            label: Text(interest),
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Budget
                  _buildSectionTitle('Budget'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\$${widget.trip.budget.toStringAsFixed(2)}',
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total budget for this trip',
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

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DayPlannerScreen(tripId: widget.trip.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('View Planner'),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    CreateTripScreen(tripToEdit: widget.trip),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Trip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
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
    );
  }
}
