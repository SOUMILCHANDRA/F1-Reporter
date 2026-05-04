import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../providers/api_providers.dart';
import '../widgets/pitwall_widgets.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int selectedYear = DateTime.now().year;
  late Timer _timer;
  Duration _countdown = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider(selectedYear));

    return Scaffold(
      appBar: AppBar(
        title: Text('$selectedYear CALENDAR', style: AppConfig.displayStyle.copyWith(fontSize: 20)),
      ),
      body: scheduleAsync.when(
        data: (events) => _buildScheduleList(events),
        loading: () => const Center(child: CircularProgressIndicator(color: AppConfig.accentRed)),
        error: (err, stack) => const Center(child: Text('Schedule unavailable')),
      ),
    );
  }

  Widget _buildScheduleList(List<dynamic> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final raceDate = DateTime.parse(event['date_race'] ?? DateTime.now().toIso8601String());
        final isNext = raceDate.isAfter(DateTime.now()) && 
            (index == 0 || DateTime.parse(events[index-1]['date_race']).isBefore(DateTime.now()));
        final isPast = raceDate.isBefore(DateTime.now());

        return _buildRaceCard(event, raceDate, isNext, isPast);
      },
    );
  }

  Widget _buildRaceCard(dynamic event, DateTime date, bool isNext, bool isPast) {
    return PitwallCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderColor: isNext ? AppConfig.accentRed : null,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('ROUND ${event['round_number']}', 
                            style: AppConfig.monoStyle.copyWith(fontSize: 10, color: AppConfig.accentRed, fontWeight: FontWeight.bold)),
                          if (event['event_format']?.toString().contains('sprint') ?? false)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2)),
                              child: const Text('SPRINT', style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event['event_name'].toString().toUpperCase(), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(DateFormat('dd-MM MMM').format(date).toUpperCase(), 
                        style: TextStyle(color: AppConfig.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(event['country_code'] ?? '🏁', style: const TextStyle(fontSize: 24)),
              ],
            ),
          ),
          if (isNext) _buildLiveCountdown(date),
          if (isPast) Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
            child: const Center(child: Text('SESSION COMPLETE', style: TextStyle(fontSize: 10, color: Colors.white24))),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCountdown(DateTime raceDate) {
    final diff = raceDate.difference(DateTime.now());
    if (diff.isNegative) return const SizedBox.shrink();

    final d = diff.inDays.toString().padLeft(2, '0');
    final h = (diff.inHours % 24).toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: AppConfig.accentRed, borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))),
      child: Column(
        children: [
          const Text('LIGHTS OUT IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text('$d:$h:$m:$s', style: AppConfig.displayStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
