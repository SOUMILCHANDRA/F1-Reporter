import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../providers/api_providers.dart';
import '../widgets/race_hub_tabs.dart';

class RaceHubScreen extends ConsumerStatefulWidget {
  const RaceHubScreen({super.key});

  @override
  ConsumerState<RaceHubScreen> createState() => _RaceHubScreenState();
}

class _RaceHubScreenState extends ConsumerState<RaceHubScreen> {
  int selectedYear = DateTime.now().year;
  int selectedRound = 1;
  String selectedSession = 'Race';
  String activeSubTab = 'Results';

  final List<String> sessions = [
    'Race',
    'Qualifying',
    'Sprint',
    'FP1',
    'FP2',
    'FP3',
  ];
  final List<String> subTabs = [
    'Results',
    'Laps',
    'Tyres',
    'Positions',
    'Telemetry',
    'Weather',
    'RC',
    'Fastest',
    'Pits',
  ];

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider(selectedYear));

    return Scaffold(
      appBar: AppBar(
        title: _buildEventPicker(scheduleAsync),
        actions: [_buildYearPicker()],
      ),
      body: Column(
        children: [
          _buildSessionPicker(),
          _buildSubTabSwitcher(),
          Expanded(child: _buildActiveTabContent()),
        ],
      ),
    );
  }

  Widget _buildEventPicker(AsyncValue<List<dynamic>> schedule) {
    return schedule.when(
      data: (events) {
        final currentEvent = events.firstWhere(
          (e) => e['round_number'] == selectedRound,
          orElse: () => events[0],
        );
        return PopupMenuButton<int>(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: AppConfig.accentRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'RD $selectedRound / ${currentEvent['event_name']}'
                    .toUpperCase(),
                style: AppConfig.monoStyle.copyWith(fontSize: 14),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white60),
            ],
          ),
          onSelected: (rd) => setState(() => selectedRound = rd),
          itemBuilder: (context) => events
              .map<PopupMenuEntry<int>>(
                (e) => PopupMenuItem<int>(
                  value: e['round_number'],
                  child: Text('RD ${e['round_number']}: ${e['event_name']}'),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Text('LOADING EVENT...'),
      error: (_, _) => const Text('SELECT EVENT'),
    );
  }

  Widget _buildYearPicker() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.history),
      onSelected: (year) => setState(() {
        selectedYear = year;
        selectedRound = 1; // Reset to round 1 when year changes
      }),
      itemBuilder: (context) {
        final currentYear = DateTime.now().year;
        final years = List.generate(
          currentYear - 1950 + 1,
          (i) => currentYear - i,
        );
        return years
            .map((y) => PopupMenuItem(value: y, child: Text(y.toString())))
            .toList();
      },
    );
  }

  Widget _buildSessionPicker() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppConfig.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final s = sessions[index];
          final active = selectedSession == s;
          return GestureDetector(
            onTap: () => setState(() => selectedSession = s),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              alignment: Alignment.center,
              child: Text(
                s.toUpperCase(),
                style: TextStyle(
                  color: active ? Colors.white : Colors.white24,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubTabSwitcher() {
    return Container(
      height: 40,
      color: AppConfig.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subTabs.length,
        itemBuilder: (context, index) {
          final t = subTabs[index];
          final active = activeSubTab == t;
          return GestureDetector(
            onTap: () => setState(() => activeSubTab = t),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppConfig.accentRed : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                t.toUpperCase(),
                style: TextStyle(
                  color: active ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTabContent() {
    // These widgets will be implemented in presentation/widgets/race_hub_tabs.dart
    switch (activeSubTab) {
      case 'Results':
        return ResultsTab(
          year: selectedYear,
          round: selectedRound,
          session: selectedSession,
        );
      case 'Laps':
        return LapsTab(
          year: selectedYear,
          round: selectedRound,
          session: selectedSession,
        );
      case 'Tyres':
        return TyresTab(
          year: selectedYear,
          round: selectedRound,
          session: selectedSession,
        );
      case 'Telemetry':
        return TelemetryTab(
          year: selectedYear,
          round: selectedRound,
          session: selectedSession,
        );
      case 'Weather':
        return WeatherTab(
          year: selectedYear,
          round: selectedRound,
          session: selectedSession,
        );
      case 'RC':
        return RaceControlTab(
          year: selectedYear,
          round: selectedRound,
          session: selectedSession,
        );
      case 'Fastest':
        return FastestLapsTab(
          year: selectedYear,
          round: selectedRound,
          sessionName: selectedSession,
        );
      case 'Pits':
        return PitStopsTab(
          year: selectedYear,
          round: selectedRound,
          session: selectedSession,
        );
      default:
        return Center(child: Text('$activeSubTab DATA STREAMING...'));
    }
  }
}
