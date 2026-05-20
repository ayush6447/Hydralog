import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/water_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Force dark status bar icons (white text on dark bg)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => WaterProvider(),
      child: const FlowTrackApp(),
    ),
  );
}

class FlowTrackApp extends StatelessWidget {
  const FlowTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF64D2FF),
          secondary: Color(0xFF30D158),
          surface: Color(0xFF1C1C1E),
          background: Colors.black,
        ),
        // Bottom nav
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C1E),
          selectedItemColor: Color(0xFF64D2FF),
          unselectedItemColor: Color(0xFF636366),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          elevation: 0,
        ),
        // Dialogs
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1C1C1E),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        // Text
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        fontFamily: '.SF Pro Display',
        useMaterial3: true,
      ),
      home: const SplashScreen(nextScreen: AuthGate()),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF64D2FF), strokeWidth: 2),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<WaterProvider>().loadData(isSignedIn: true);
        });
        return const FlowTrackHome();
      },
    );
  }
}

class FlowTrackHome extends StatefulWidget {
  const FlowTrackHome({super.key});

  @override
  State<FlowTrackHome> createState() => _FlowTrackHomeState();
}

class _FlowTrackHomeState extends State<FlowTrackHome> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final success = await NotificationService.initialize();
    if (success) {
      await NotificationService.scheduleDailyReminders();
      // Debug: log pending count
      final pending = await NotificationService.getPendingNotifications();
      debugPrint('[FlowTrack] ${pending.length} notifications pending');
    } else {
      debugPrint('[FlowTrack] ⚠ Notification init failed – check logs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF64D2FF), strokeWidth: 2),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              border: Border(
                top: BorderSide(
                    color: Colors.white.withOpacity(0.08), width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: const Color(0xFF64D2FF),
                unselectedItemColor: const Color(0xFF636366),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.heart_broken_outlined),
                    activeIcon: Icon(Icons.favorite_rounded),
                    label: 'Summary',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_outlined),
                    activeIcon: Icon(Icons.calendar_month_rounded),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
