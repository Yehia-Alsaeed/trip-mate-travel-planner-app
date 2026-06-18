import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../components/app_text_styles.dart';
import '../login/login_screen.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AuthViewModel>(
        builder: (context, authVm, _) {
          return ListView(
            children: [
              // User info section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Account', style: AppTextStyles.heading3),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(
                            authVm.userName ?? 'Not set',
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // App settings
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('About'),
                        subtitle: Text('Trip Mate v1.0.0'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text(
                                    'Are you sure you want to logout?',
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
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                          );

                          if (confirmed == true && context.mounted) {
                            authVm.logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
