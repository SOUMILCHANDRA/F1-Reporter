import 'package:flutter/material.dart';
import '../../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';

class StandingEntry {
  final int position;
  final String driverName;
  final String teamName;
  final int points;
  final Color teamColor;
  final double relativePoints; // 0.0 to 1.0

  StandingEntry({
    required this.position,
    required this.driverName,
    required this.teamName,
    required this.points,
    required this.teamColor,
    required this.relativePoints,
  });
}

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  bool isDrivers = true;

  final List<StandingEntry> driverStandings = [
    StandingEntry(
      position: 1,
      driverName: 'Max Verstappen',
      teamName: 'Red Bull Racing',
      points: 454,
      teamColor: PitwallTheme.teamRedBull,
      relativePoints: 1.0,
    ),
    StandingEntry(
      position: 2,
      driverName: 'Lando Norris',
      teamName: 'McLaren',
      points: 315,
      teamColor: PitwallTheme.teamMcLaren,
      relativePoints: 0.69,
    ),
    StandingEntry(
      position: 3,
      driverName: 'Charles Leclerc',
      teamName: 'Ferrari',
      points: 291,
      teamColor: PitwallTheme.teamFerrari,
      relativePoints: 0.64,
    ),
    StandingEntry(
      position: 4,
      driverName: 'Oscar Piastri',
      teamName: 'McLaren',
      points: 262,
      teamColor: PitwallTheme.teamMcLaren,
      relativePoints: 0.57,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('STANDINGS', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
      ),
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: driverStandings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildStandingRow(driverStandings[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 40,
        width: 240,
        decoration: BoxDecoration(
          color: PitwallTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PitwallTheme.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(child: _toggleButton('Drivers', isDrivers, () => setState(() => isDrivers = true))),
            Expanded(child: _toggleButton('Constructors', !isDrivers, () => setState(() => isDrivers = false))),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? PitwallTheme.primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStandingRow(StandingEntry entry) {
    return PitwallCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Position & Team Color Border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: entry.teamColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
            const SizedBox(width: 16),
            _buildPositionMarker(entry.position),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(entry.teamName.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10)),
                          ],
                        ),
                        TimingText('${entry.points} PTS', fontSize: 14, fontWeight: FontWeight.bold),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProgressBar(entry.relativePoints, entry.teamColor),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionMarker(int pos) {
    Color color = Colors.white24;
    if (pos == 1) color = PitwallTheme.secondaryAccent;
    if (pos == 2) color = const Color(0xFFC0C0C0);
    if (pos == 3) color = const Color(0xFFCD7F32);

    return Container(
      width: 32,
      alignment: Alignment.center,
      child: Text(
        pos.toString(),
        style: PitwallTheme.monoStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
