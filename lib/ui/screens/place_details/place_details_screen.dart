import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/planner_vm.dart';
import '../../../viewmodels/trips_vm.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../../viewmodels/saved_vm.dart';
import '../../../data/models/place.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Duration _selectedDuration = const Duration(hours: 1);
  bool _isSaved = false;
  bool _isCheckingSaved = true;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDuration() async {
    final hours = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Duration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(8, (index) {
                final hours = index + 1;
                return ListTile(
                  title: Text('$hours ${hours == 1 ? 'hour' : 'hours'}'),
                  onTap: () => Navigator.pop(context, hours),
                );
              }),
            ),
          ),
    );
    if (hours != null) {
      setState(() {
        _selectedDuration = Duration(hours: hours);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfSaved();
    });
  }

  Future<void> _checkIfSaved() async {
    final authVm = context.read<AuthViewModel>();
    final savedVm = context.read<SavedViewModel>();

    if (authVm.userId != null) {
      // Load saved places first to ensure the set is populated
      await savedVm.loadSavedPlaces(authVm.userId!);

      // Check if place is in the saved set
      final isSaved = savedVm.savedPlaceIds.contains(widget.place.id);
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
          _isCheckingSaved = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isCheckingSaved = false;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final authVm = context.read<AuthViewModel>();
    final savedVm = context.read<SavedViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    if (authVm.userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final wasSaved = _isSaved;
    setState(() {
      _isSaved = !_isSaved;
    });

    final success =
        !wasSaved
            ? await savedVm.savePlace(
              authVm.userId!,
              widget.place.id,
              place: widget.place,
            )
            : await savedVm.unsavePlace(authVm.userId!, widget.place.id);

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              !wasSaved
                  ? 'Place saved successfully'
                  : 'Place removed from saved',
            ),
          ),
        );
      } else {
        // Revert the state on failure
        setState(() {
          _isSaved = wasSaved;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              savedVm.errorMessage ??
                  'Failed to ${!wasSaved ? 'save' : 'unsave'} place',
            ),
          ),
        );
      }
    }
  }

  Future<void> _addToPlanner() async {
    final authVm = context.read<AuthViewModel>();
    final tripsVm = context.read<TripsViewModel>();
    final plannerVm = context.read<PlannerViewModel>();

    if (authVm.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    // Check if user has a current trip
    if (tripsVm.currentTrip == null) {
      final createTrip = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('No Active Trip'),
              content: const Text(
                'You need to create a trip first before adding places to your planner.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Create Trip'),
                ),
              ],
            ),
      );

      if (createTrip == true) {
        Navigator.pop(context);
        // Navigate to create trip screen
        return;
      }
      return;
    }

    // Validate date and time
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    final tripId = tripsVm.currentTrip!.id;
    final success = await plannerVm.addPlannerItem(
      tripId: tripId,
      placeId: widget.place.id,
      date: _selectedDate!,
      startTime: _selectedTime!,
      duration: _selectedDuration,
      place: widget.place, // Pass Place object to store
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place added to planner successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              plannerVm.errorMessage ?? 'Failed to add place to planner',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with placeholder (photos removed)
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary.withOpacity(0.3),
                child: const Icon(
                  Icons.image,
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
                  // Name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(place.name, style: AppTextStyles.heading2),
                      ),
                      if (place.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: AppTextStyles.bodyLarge,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Save button (bookmark icon)
                  if (!_isCheckingSaved)
                    InkWell(
                      onTap: _toggleSave,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _isSaved
                                  ? Colors.amber.withOpacity(0.2)
                                  : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _isSaved
                                    ? Colors.amber
                                    : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color:
                                  _isSaved ? Colors.amber : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSaved ? 'Saved' : 'Save',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color:
                                    _isSaved ? Colors.amber : AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Category and distance
                  Row(
                    children: [
                      Chip(
                        label: Text(place.category),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                      ),
                      if (place.distance != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${place.distance!.toStringAsFixed(1)} km away',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  if (place.address != null)
                    ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: const Text('Address'),
                      subtitle: Text(place.address!),
                      contentPadding: EdgeInsets.zero,
                    ),

                  // Opening hours
                  if (place.openingHours != null)
                    ListTile(
                      leading: const Icon(
                        Icons.access_time,
                        color: AppColors.primary,
                      ),
                      title: const Text('Opening Hours'),
                      subtitle: Text(place.openingHours!),
                      contentPadding: EdgeInsets.zero,
                    ),

                  // Phone
                  if (place.phone != null)
                    ListTile(
                      leading: const Icon(
                        Icons.phone,
                        color: AppColors.primary,
                      ),
                      title: const Text('Phone'),
                      subtitle: Text(place.phone!),
                      contentPadding: EdgeInsets.zero,
                    ),

                  // Website
                  if (place.website != null)
                    ListTile(
                      leading: const Icon(
                        Icons.language,
                        color: AppColors.primary,
                      ),
                      title: const Text('Website'),
                      subtitle: Text(place.website!),
                      contentPadding: EdgeInsets.zero,
                    ),

                  const Divider(height: 32),

                  // Add to Planner Section
                  const Text('Add to Planner', style: AppTextStyles.heading3),
                  const SizedBox(height: 16),

                  // Date selection
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                    title: const Text('Date'),
                    subtitle: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Select date',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectDate,
                  ),

                  // Time selection
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: AppColors.primary,
                    ),
                    title: const Text('Start Time'),
                    subtitle: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select time',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectTime,
                  ),

                  // Duration selection
                  ListTile(
                    leading: const Icon(Icons.timer, color: AppColors.primary),
                    title: const Text('Duration'),
                    subtitle: Text(
                      '${_selectedDuration.inHours} ${_selectedDuration.inHours == 1 ? 'hour' : 'hours'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectDuration,
                  ),

                  const SizedBox(height: 24),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _addToPlanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add to Planner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
