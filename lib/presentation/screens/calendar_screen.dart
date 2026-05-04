import 'package:flutter/material.dart';
import '../../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';

class RaceEvent {
  final int round;
  final String gpName;
  final String dateRange;
  final bool isNext;
  final bool isPast;
  final bool isSprint;
  final String? winner;

  RaceEvent({
    required this.round,
    required this.gpName,
    required this.dateRange,
    this.isNext = false,
    this.isPast = false,
    this.isSprint = false,
    this.winner,
  });
}

class CalendarScreen extends StatelessWidget {
  CalendarScreen({super.key});

  final List<RaceEvent> events = [
    RaceEvent(round: 1, gpName: 'Bahrain Grand Prix', dateRange: '02-04 MAR', isPast: true, winner: 'VER'),
    RaceEvent(round: 2, gpName: 'Saudi Arabian Grand Prix', dateRange: '07-09 MAR', isPast: true, winner: 'VER'),
    RaceEvent(round: 3, gpName: 'Australian Grand Prix', dateRange: '22-24 MAR', isPast: true, winner: 'SAI'),
    RaceEvent(round: 4, gpName: 'Japanese Grand Prix', dateRange: '05-07 APR', isNext: true, isSprint: true),
    RaceEvent(round: 5, gpName: 'Chinese Grand Prix', dateRange: '19-21 APR'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('2024 CALENDAR', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildRaceCard(events[index]),
      ),
    );
  }

  Widget _buildRaceCard(RaceEvent event) {
    return PitwallCard(
      borderColor: event.isNext ? PitwallTheme.primaryAccent : null,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ROUND ${event.round}', style: PitwallTheme.monoStyle.copyWith(fontSize: 10, color: PitwallTheme.primaryAccent)),
                    const SizedBox(height: 4),
                    Text(event.gpName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(event.dateRange, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                if (event.isSprint)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                    child: const Text('SPRINT', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (event.isPast && event.winner != null)
                   Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: PitwallTheme.cardBorder, borderRadius: BorderRadius.circular(4)),
                    child: Text('P1: ${event.winner}', style: PitwallTheme.monoStyle.copyWith(fontSize: 10, color: PitwallTheme.secondaryAccent)),
                  ),
              ],
            ),
          ),
          if (event.isNext) _buildCountdown(),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: PitwallTheme.primaryAccent,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'LIGHTS OUT IN: 04:12:35:09',
            style: PitwallTheme.monoStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
