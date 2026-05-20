import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/water_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  await NotificationService.cancelAllNotifications();
  await NotificationService.scheduleDailyRandomReminders();

  runApp(
    ChangeNotifierProvider(
      create: (_) => WaterProvider(),
      child: const HydralogApp(),
    ),
  );
}

class HydralogApp extends StatelessWidget {
  const HydralogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydralog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.tealAccent,
        ),
        dialogBackgroundColor: const Color(0xFF1E1E1E),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

/// Listens to Firebase auth state and shows Login or Home accordingly
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        // User is signed in — boot data load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<WaterProvider>().loadData(isSignedIn: true);
        });
        return const HydralogHome();
      },
    );
  }
}

class HydralogHome extends StatefulWidget {
  const HydralogHome({super.key});

  @override
  State<HydralogHome> createState() => _HydralogHomeState();
}

class _HydralogHomeState extends State<HydralogHome> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  static const _titles = ['Hydralog', 'History', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            actions: [
              // User avatar
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                    child: Text(
                      AuthService.currentUser?.displayName
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          '?',
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: _screens),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.cyanAccent,
            unselectedItemColor: Colors.white38,
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today), label: 'History'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
