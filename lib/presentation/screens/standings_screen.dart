import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';
import '../../providers/api_providers.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  bool isDrivers = true;
  final int currentYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final standingsAsync = isDrivers 
        ? ref.watch(driverStandingsProvider(currentYear))
        : ref.watch(constructorStandingsProvider(currentYear));

    return Scaffold(
      appBar: AppBar(
        title: Text('STANDINGS', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
      ),
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: standingsAsync.when(
              data: (standings) {
                if (standings.isEmpty) {
                  return const Center(child: Text('No standings data found.', style: TextStyle(color: Colors.white60)));
                }
                
                final double maxPoints = (standings[0]['points'] as num).toDouble();
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: standings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = standings[index];
                    final double relativePoints = maxPoints > 0 
                        ? (entry['points'] as num).toDouble() / maxPoints 
                        : 0.0;
                        
                    return _buildStandingRow(
                      position: entry['position'],
                      name: isDrivers ? entry['full_name'] : entry['team_name'],
                      subtitle: isDrivers ? entry['team'] : entry['nationality'],
                      points: (entry['points'] as num).toInt(),
                      relativePoints: relativePoints,
                      teamColor: _getTeamColor(isDrivers ? entry['team'] : entry['team_name']),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: PitwallTheme.primaryAccent)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white60))),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(String teamName) {
    teamName = teamName.toLowerCase();
    if (teamName.contains('red bull')) return PitwallTheme.teamRedBull;
    if (teamName.contains('ferrari')) return PitwallTheme.teamFerrari;
    if (teamName.contains('mclaren')) return PitwallTheme.teamMcLaren;
    if (teamName.contains('mercedes')) return const Color(0xFF00D2BE);
    if (teamName.contains('aston martin')) return const Color(0xFF006F62);
    if (teamName.contains('alpine')) return const Color(0xFF0090FF);
    if (teamName.contains('williams')) return const Color(0xFF005AFF);
    if (teamName.contains('rb') || teamName.contains('visa')) return const Color(0xFF0000FF);
    if (teamName.contains('sauber') || teamName.contains('kick')) return const Color(0xFF52E252);
    if (teamName.contains('haas')) return const Color(0xFFFFFFFF);
    return Colors.white24;
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

  Widget _buildStandingRow({
    required int position,
    required String name,
    required String subtitle,
    required int points,
    required double relativePoints,
    required Color teamColor,
  }) {
    return PitwallCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
            const SizedBox(width: 16),
            _buildPositionMarker(position),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                              Text(subtitle.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        TimingText('$points PTS', fontSize: 14, fontWeight: FontWeight.bold),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProgressBar(relativePoints, teamColor),
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
