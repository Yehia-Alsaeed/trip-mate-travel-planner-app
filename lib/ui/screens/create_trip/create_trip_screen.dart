import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/trips_vm.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../../data/models/trip.dart';
import '../../components/form_fields.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';

class CreateTripScreen extends StatefulWidget {
  final Trip? tripToEdit;

  const CreateTripScreen({super.key, this.tripToEdit});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _interestsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedInterests = [];

  final List<String> _availableInterests = [
    'Ancient',
    'Medical',
    'Nature',
    'Shopping',
    'Food',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    if (widget.tripToEdit != null) {
      final trip = widget.tripToEdit!;
      _cityController.text = trip.city;
      _countryController.text = trip.country;
      _budgetController.text = trip.budget.toString();
      _startDate = trip.startDate;
      _endDate = trip.endDate;
      _selectedInterests = List<String>.from(trip.interests);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _budgetController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    final authVm = context.read<AuthViewModel>();
    final tripsVm = context.read<TripsViewModel>();

    if (authVm.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    bool success;
    if (widget.tripToEdit != null) {
      // Update existing trip
      final updatedTrip = widget.tripToEdit!.copyWith(
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        budget: double.parse(_budgetController.text.trim()),
        interests: _selectedInterests,
      );
      success = await tripsVm.updateTrip(updatedTrip);
    } else {
      // Create new trip
      success = await tripsVm.createTrip(
        userId: authVm.userId!,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        budget: double.parse(_budgetController.text.trim()),
        interests: _selectedInterests,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.tripToEdit != null
                ? 'Trip updated successfully!'
                : 'Trip created successfully!',
          ),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tripsVm.errorMessage ?? 'Failed to save trip')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tripToEdit != null ? 'Edit Trip' : 'Plan your next trip',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.tripToEdit != null
                      ? 'Edit Trip'
                      : 'Plan your next trip',
                  style: AppTextStyles.heading2,
                ),
              ),
              const SizedBox(height: 24),

              // Country field
              FormFields.textField(
                label: 'Enter Country',
                controller: _countryController,
                hintText: 'Enter Country',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Country is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City field
              FormFields.textField(
                label: 'Enter City',
                controller: _cityController,
                hintText: 'Enter City',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Budget field
              FormFields.textField(
                label: 'Budget',
                controller: _budgetController,
                hintText: 'Enter Budget',
                keyboardType: TextInputType.number,
                errorText:
                    _budgetController.text.isNotEmpty &&
                            (double.tryParse(_budgetController.text) == null)
                        ? 'must enter a number'
                        : null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Budget is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'must enter a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interests field
              FormFields.textField(
                label: 'Enter Interests',
                controller: _interestsController,
                hintText: 'Select interests below',
                readOnly: true,
                validator: (value) {
                  if (_selectedInterests.isEmpty) {
                    return 'At least one interest is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _availableInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (_) => _toggleInterest(interest),
                        selectedColor: AppColors.primary.withOpacity(0.3),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Date fields
              Builder(
                builder:
                    (context) => FormFields.dateField(
                      context: context,
                      label: 'Enter date',
                      selectedDate: _startDate,
                      onDateSelected: (date) {
                        setState(() {
                          _startDate = date;
                        });
                      },
                      errorText:
                          _startDate == null ? 'Start date is required' : null,
                    ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder:
                    (context) => FormFields.dateField(
                      context: context,
                      label: 'End date',
                      selectedDate: _endDate,
                      onDateSelected: (date) {
                        setState(() {
                          _endDate = date;
                        });
                      },
                      errorText:
                          _endDate == null ? 'End date is required' : null,
                    ),
              ),
              const SizedBox(height: 24),

              // Save button
              Consumer<TripsViewModel>(
                builder: (context, tripsVm, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: tripsVm.isLoading ? null : _saveTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          tripsVm.isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                widget.tripToEdit != null ? 'Update' : 'Save',
                                style: AppTextStyles.buttonText,
                              ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
