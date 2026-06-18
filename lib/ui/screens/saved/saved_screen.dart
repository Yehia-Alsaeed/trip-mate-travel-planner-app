import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/saved_vm.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../../data/models/place.dart';
import '../../components/place_card.dart';
import '../../components/app_colors.dart';
import '../../components/app_text_styles.dart';
import '../place_details/place_details_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVm = context.read<AuthViewModel>();
      final savedVm = context.read<SavedViewModel>();

      if (authVm.userId != null) {
        savedVm.loadSavedPlaces(authVm.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: Consumer2<AuthViewModel, SavedViewModel>(
        builder: (context, authVm, savedVm, _) {
          if (authVm.userId == null) {
            return const Center(child: Text('Please login'));
          }

          if (savedVm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (savedVm.savedPlaces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text('No saved places', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  const Text(
                    'Save places to view them here',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await savedVm.loadSavedPlaces(authVm.userId!);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: savedVm.savedPlaces.length,
              itemBuilder: (context, index) {
                final place = savedVm.savedPlaces[index];
                return PlaceCard(
                  place: place,
                  showMenu: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailsScreen(place: place),
                      ),
                    );
                  },
                  onMenuTap: () {
                    _showRemoveDialog(context, savedVm, authVm, place);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    SavedViewModel savedVm,
    AuthViewModel authVm,
    Place place,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remove from saved',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    if (authVm.userId != null) {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await savedVm.unsavePlace(
                        authVm.userId!,
                        place.id,
                      );
                      if (context.mounted) {
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Place removed from saved'),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                savedVm.errorMessage ??
                                    'Failed to remove place',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }
}
