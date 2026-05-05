import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../config/app_config.dart';
import '../providers/api_providers.dart';
import '../widgets/pitwall_widgets.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  bool isDrivers = true;
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final standingsAsync = ref.watch(isDrivers 
        ? driverStandingsProvider(selectedYear) 
        : constructorStandingsProvider(selectedYear));

    return Scaffold(
      appBar: AppBar(
        title: Text('STANDINGS', style: AppConfig.displayStyle.copyWith(fontSize: 20)),
        actions: [
          _buildYearPicker(),
        ],
      ),
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: standingsAsync.when(
              data: (data) => _buildStandingsList(data),
              loading: () => const Center(child: CircularProgressIndicator(color: AppConfig.accentRed)),
              error: (err, stack) => Center(child: Text('Standings unavailable')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.history),
      onSelected: (year) => setState(() => selectedYear = year),
      itemBuilder: (context) {
        final currentYear = DateTime.now().year;
        final years = List.generate(currentYear - 1950 + 1, (i) => currentYear - i);
        return years.map((y) => PopupMenuItem(value: y, child: Text(y.toString()))).toList();
      },
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toggleBtn('DRIVERS', isDrivers, () => setState(() => isDrivers = true)),
          const SizedBox(width: 12),
          _toggleBtn('CONSTRUCTORS', !isDrivers, () => setState(() => isDrivers = false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppConfig.accentRed : AppConfig.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.transparent : AppConfig.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStandingsList(List<dynamic> list) {
    if (list.isEmpty) return const Center(child: Text('No data found'));
    final double maxPoints = (list[0]['points'] as num).toDouble();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final entry = list[index];
        final pos = entry['position'] as int;
        final points = (entry['points'] as num).toDouble();
        final teamColor = _getTeamColor(isDrivers ? entry['team'] : entry['team_name']);

        return PitwallCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, decoration: BoxDecoration(color: teamColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)))),
                const SizedBox(width: 12),
                _posBadge(pos),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isDrivers ? entry['full_name'] : entry['team_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${points.toInt()} PTS', style: AppConfig.monoStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 4,
                          percent: maxPoints > 0 ? points / maxPoints : 0,
                          progressColor: teamColor,
                          backgroundColor: AppConfig.border,
                          barRadius: const Radius.circular(2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _posBadge(int pos) {
    Color color = AppConfig.textSecondary;
    if (pos == 1) color = AppConfig.accentGold;
    if (pos == 2) color = const Color(0xFFC0C0C0); // Silver
    if (pos == 3) color = const Color(0xFFCD7F32); // Bronze

    return Container(
      width: 32,
      alignment: Alignment.center,
      child: Text(pos.toString(), style: AppConfig.displayStyle.copyWith(fontSize: 18, color: color)),
    );
  }

  Color _getTeamColor(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('red bull')) return const Color(0xFF3671C6);
    if (n.contains('ferrari')) return const Color(0xFFE8002D);
    if (n.contains('mclaren')) return const Color(0xFFFF8700);
    if (n.contains('mercedes')) return const Color(0xFF27F4D2);
    if (n.contains('aston martin')) return const Color(0xFF229971);
    if (n.contains('alpine')) return const Color(0xFF0093CC);
    if (n.contains('williams')) return const Color(0xFF64C4FF);
    if (n.contains('rb') || n.contains('visa')) return const Color(0xFF6692FF);
    if (n.contains('sauber')) return const Color(0xFF52E252);
    if (n.contains('haas')) return const Color(0xFFB6BABD);
    return Colors.white24;
  }
}
