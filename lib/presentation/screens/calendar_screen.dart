import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';
import '../../providers/api_providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentYear = DateTime.now().year;
    final scheduleAsync = ref.watch(scheduleProvider(currentYear));

    return Scaffold(
      appBar: AppBar(
        title: Text('$currentYear CALENDAR', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
      ),
      body: scheduleAsync.when(
        data: (events) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildRaceCard(event);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: PitwallTheme.primaryAccent)),
        error: (err, stack) => Center(child: Text('Schedule unavailable: $err', style: const TextStyle(color: Colors.white60))),
      ),
    );
  }

  Widget _buildRaceCard(dynamic event) {
    final String gpName = event['event_name'] ?? 'Unknown Grand Prix';
    final int round = event['round_number'] ?? 0;
    final String? raceDateStr = event['date_race'];
    
    String dateRange = 'TBC';
    bool isPast = false;
    if (raceDateStr != null) {
      final raceDate = DateTime.parse(raceDateStr);
      dateRange = DateFormat('dd-MM MMM').format(raceDate).toUpperCase();
      isPast = raceDate.isBefore(DateTime.now());
    }

    final bool isSprint = event['event_format']?.toString().contains('sprint') ?? false;

    return PitwallCard(
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
                      Text('ROUND $round', style: PitwallTheme.monoStyle.copyWith(fontSize: 10, color: PitwallTheme.primaryAccent)),
                      const SizedBox(height: 4),
                      Text(gpName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(dateRange, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                if (isSprint)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                    child: const Text('SPRINT', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (isPast)
                   Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: PitwallTheme.cardBorder, borderRadius: BorderRadius.circular(4)),
                    child: Text('FINISHED', style: PitwallTheme.monoStyle.copyWith(fontSize: 10, color: Colors.white60)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
