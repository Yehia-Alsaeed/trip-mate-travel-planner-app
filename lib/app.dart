import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/screens/get_started/get_started_screen.dart';
import 'ui/screens/login/login_screen.dart';
import 'ui/components/bottom_nav_scaffold.dart';
import 'viewmodels/auth_vm.dart';
import 'viewmodels/trips_vm.dart';
import 'viewmodels/planner_vm.dart';
import 'viewmodels/discover_vm.dart';
import 'viewmodels/saved_vm.dart';
import 'viewmodels/theme_vm.dart';
import 'viewmodels/countries_vm.dart';
import 'viewmodels/recommended_countries_vm.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => TripsViewModel()),
        ChangeNotifierProvider(create: (_) => PlannerViewModel()),
        ChangeNotifierProvider(create: (_) => DiscoverViewModel()),
        ChangeNotifierProvider(create: (_) => SavedViewModel()),
        ChangeNotifierProvider(create: (_) => CountriesViewModel()),
        ChangeNotifierProvider(create: (_) => RecommendedCountriesViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVm, _) {
          return MaterialApp(
            title: 'Trip Mate',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD4A574), // Light brown theme
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD4A574), // Light brown theme
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeVm.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppNavigator(),
          );
        },
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        // Check authentication state
        if (authVm.isAuthenticated) {
          return const BottomNavScaffold();
        } else if (authVm.hasSeenGetStarted) {
          return const LoginScreen();
        } else {
          return const GetStartedScreen();
        }
      },
    );
  }
}
