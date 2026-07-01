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
        title: Text(
          '$selectedYear CALENDAR',
          style: AppConfig.displayStyle.copyWith(fontSize: 20),
        ),
        actions: [_buildYearPicker()],
      ),
      body: scheduleAsync.when(
        data: (events) => _buildScheduleList(events),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppConfig.accentRed),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppConfig.accentRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Schedule unavailable',
                style: AppConfig.displayStyle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.accentRed,
                ),
                onPressed: () => ref.refresh(scheduleProvider(selectedYear)),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearPicker() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.history),
      onSelected: (year) => setState(() => selectedYear = year),
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

  Widget _buildScheduleList(List<dynamic> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final raceDate = DateTime.parse(
          event['date_race'] ?? DateTime.now().toIso8601String(),
        );
        final prevRaceDateStr = index > 0
            ? events[index - 1]['date_race']
            : null;
        final prevRaceDate = prevRaceDateStr != null
            ? DateTime.parse(prevRaceDateStr)
            : null;

        final isNext =
            raceDate.isAfter(DateTime.now()) &&
            (index == 0 ||
                (prevRaceDate != null &&
                    prevRaceDate.isBefore(DateTime.now())));

        final isPast = raceDate.isBefore(DateTime.now());

        return _buildRaceCard(event, raceDate, isNext, isPast);
      },
    );
  }

  Widget _buildRaceCard(
    dynamic event,
    DateTime date,
    bool isNext,
    bool isPast,
  ) {
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
                          Text(
                            'ROUND ${event['round_number']}',
                            style: AppConfig.monoStyle.copyWith(
                              fontSize: 10,
                              color: AppConfig.accentRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (event['event_format']?.toString().contains(
                                'sprint',
                              ) ??
                              false)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text(
                                'SPRINT',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event['event_name'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('dd-MM MMM').format(date).toUpperCase(),
                        style: TextStyle(
                          color: AppConfig.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  event['country_code'] ?? '🏁',
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
          if (isNext) _buildLiveCountdown(date),
          if (isPast)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'SESSION COMPLETE',
                    style: TextStyle(fontSize: 10, color: Colors.white24),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.map,
                      size: 14,
                      color: AppConfig.accentRed,
                    ),
                    onPressed: () =>
                        _showTrackMap(event['event_name'].toString()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'View Circuit',
                  ),
                ],
              ),
            ),
          if (!isPast && !isNext)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                icon: const Icon(Icons.map, size: 16, color: Colors.white24),
                onPressed: () => _showTrackMap(event['event_name'].toString()),
                tooltip: 'View Circuit',
              ),
            ),
        ],
      ),
    );
  }

  void _showTrackMap(String raceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final mapAsync = ref.watch(trackMapProvider(raceName));
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      raceName.toUpperCase(),
                      style: AppConfig.displayStyle.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: mapAsync.when(
                    data: (data) {
                      if (data['error'] != null) {
                        return Center(
                          child: Text(
                            'Map not available for this circuit',
                            style: TextStyle(color: Colors.white24),
                          ),
                        );
                      }
                      return InteractiveViewer(
                        child: FutureBuilder<String>(
                          future: AppConfig.getBaseUrl(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return Image.network(
                              '${snap.data}${data['url']}',
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: AppConfig.accentRed,
                                      ),
                                    );
                                  },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppConfig.accentRed,
                      ),
                    ),
                    error: (err, _) =>
                        Center(child: Text('Error loading map: $err')),
                  ),
                ),
              ],
            ),
          );
        },
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
      decoration: const BoxDecoration(
        color: AppConfig.accentRed,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        children: [
          const Text(
            'LIGHTS OUT IN',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            '$d:$h:$m:$s',
            style: AppConfig.displayStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
