import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../../viewmodels/trips_vm.dart';
import '../../../viewmodels/saved_vm.dart';
import '../../../viewmodels/planner_vm.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.updateUserName(_nameController.text.trim());

    if (mounted) {
      if (success) {
        setState(() {
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authVm.errorMessage ?? 'Failed to update name'),
          ),
        );
      }
    }
  }

  void _startEditingName(String currentName) {
    setState(() {
      _isEditingName = true;
      _nameController.text = currentName;
    });
  }

  void _cancelEditingName() {
    setState(() {
      _isEditingName = false;
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Consumer4<
        AuthViewModel,
        TripsViewModel,
        SavedViewModel,
        PlannerViewModel
      >(
        builder: (context, authVm, tripsVm, savedVm, plannerVm, _) {
          // Load profile if not loaded
          if (authVm.userId != null && authVm.userName == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authVm.loadUserProfile();
            });
          }

          // Load data if needed
          if (authVm.userId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (tripsVm.trips.isEmpty) {
                tripsVm.loadTrips(authVm.userId!);
              }
              if (savedVm.savedPlaceIds.isEmpty) {
                savedVm.loadSavedPlaces(authVm.userId!);
              }
            });
          }

          // Get statistics
          final tripsCount = tripsVm.trips.length;
          final savedCount = savedVm.savedPlaceIds.length;
          final plannerItemsCount = plannerVm.plannerItems.length;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Profile Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.3),
                      child:
                          authVm.userFirstName != null
                              ? Text(
                                authVm.userFirstName!
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                              : const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primary,
                              ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Full Name',
                                style: AppTextStyles.heading3,
                              ),
                              if (!_isEditingName)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _startEditingName(
                                      authVm.userName ?? 'User',
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isEditingName)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your full name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  autofocus: true,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: _cancelEditingName,
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _saveName,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Text(
                              authVm.userName ?? 'Not set',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Account Information
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: AppColors.primary,
                          ),
                          title: const Text('Email'),
                          subtitle: Text(
                            _auth.currentUser?.email ?? 'Not available',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                          title: const Text('User ID'),
                          subtitle: Text(
                            authVm.userId ?? 'Not available',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Statistics Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Statistics',
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                icon: Icons.luggage,
                                label: 'Trips',
                                value: tripsCount.toString(),
                              ),
                              _buildStatItem(
                                icon: Icons.bookmark,
                                label: 'Saved',
                                value: savedCount.toString(),
                              ),
                              _buildStatItem(
                                icon: Icons.calendar_today,
                                label: 'Planned',
                                value: plannerItemsCount.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
