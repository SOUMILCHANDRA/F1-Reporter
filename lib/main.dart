import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';
import 'screens/news_feed_screen.dart';
import 'screens/race_hub_screen.dart';
import 'screens/standings_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        // You could override providers here if needed
      ],
      child: const PitwallApp(),
    ),
  );
}

class PitwallApp extends StatelessWidget {
  const PitwallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PITWALL',
      debugShowCheckedModeBanner: false,
      theme: AppConfig.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  bool _isOnline = true;

  final List<Widget> _screens = [
    const NewsFeedScreen(),
    const RaceHubScreen(),
    const StatsScreen(),
    const StandingsScreen(),
    const CalendarScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    try {
      final base = await AppConfig.getBaseUrl();
      final res = await http.get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        _showOfflineBanner('Backend returned error ${res.statusCode}');
      } else {
        if (mounted) setState(() => _isOnline = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isOnline = false);
      _showOfflineBanner('Cannot reach backend: $e — Go to Settings to update URL');
    }
  }

  void _showOfflineBanner(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFE8002D),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) => _checkBackend()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (!_isOnline)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                color: AppConfig.accentRed,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  'BACKEND OFFLINE',
                  style: AppConfig.monoStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppConfig.surface,
        selectedItemColor: AppConfig.accentRed,
        unselectedItemColor: AppConfig.textSecondary,
        selectedLabelStyle: AppConfig.bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppConfig.bodyStyle.copyWith(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'NEWS'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_motorsports), label: 'RACE HUB'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'STATS'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'STANDINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'CALENDAR'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        mini: true,
        backgroundColor: AppConfig.surface,
        child: const Icon(Icons.settings, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ).then((_) => _checkBackend()),
      ) : null,
    );
  }
}
