import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/water_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  await NotificationService.cancelAllNotifications();
  await NotificationService.scheduleDailyRandomReminders();

  runApp(
    ChangeNotifierProvider(
      create: (_) => WaterProvider()..loadData(),
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
      home: const HydralogHome(),
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

  static const List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  static const List<String> _titles = ['Hydralog', 'History', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.cyanAccent,
            unselectedItemColor: Colors.white38,
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
