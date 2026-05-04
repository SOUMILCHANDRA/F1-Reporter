import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/pitwall_theme.dart';
import 'presentation/screens/news_feed_screen.dart';
import 'presentation/screens/race_hub_screen.dart';
import 'presentation/screens/standings_screen.dart';
import 'presentation/screens/calendar_screen.dart';
import 'presentation/screens/tyre_strategy_screen.dart';

void main() {
  runApp(const ProviderScope(child: PitwallApp()));
}

class PitwallApp extends StatelessWidget {
  const PitwallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pitwall',
      debugShowCheckedModeBanner: false,
      theme: PitwallTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const NewsFeedScreen(),
    const RaceHubScreen(),
    TyreStrategyScreen(),
    const StandingsScreen(),
    CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(),
            const VerticalDivider(thickness: 1, width: 1, color: PitwallTheme.cardBorder),
            Expanded(
              flex: 7,
              child: _screens[_selectedIndex],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: PitwallTheme.cardBorder),
            Expanded(
              flex: 3,
              child: _buildDetailPanel(),
            ),
          ],
        ),
      );
    }

    // Mobile uses the BottomNavBar integrated in screens for now, 
    // but we'll centralize it here in the shell.
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      backgroundColor: PitwallTheme.background,
      indicatorColor: PitwallTheme.primaryAccent.withValues(alpha: 0.2),
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: const TextStyle(color: PitwallTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white60, fontSize: 12),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.article_outlined), label: Text('News')),
        NavigationRailDestination(icon: Icon(Icons.speed_outlined), label: Text('Race Hub')),
        NavigationRailDestination(icon: Icon(Icons.api_outlined), label: Text('Strategy')),
        NavigationRailDestination(icon: Icon(Icons.leaderboard_outlined), label: Text('Standings')),
        NavigationRailDestination(icon: Icon(Icons.calendar_today_outlined), label: Text('Calendar')),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PitwallTheme.cardBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: PitwallTheme.background,
        selectedItemColor: PitwallTheme.primaryAccent,
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: const TextStyle(fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.speed_outlined), label: 'Race Hub'),
          BottomNavigationBarItem(icon: Icon(Icons.api_outlined), label: 'Strategy'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), label: 'Standings'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Calendar'),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    return Container(
      color: PitwallTheme.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETAIL PANEL', style: PitwallTheme.monoStyle.copyWith(color: PitwallTheme.primaryAccent, fontSize: 12)),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(
              child: Text('Select an item to view details', style: TextStyle(color: Colors.white24)),
            ),
          ),
        ],
      ),
    );
  }
}
