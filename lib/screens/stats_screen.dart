import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_config.dart';
import '../providers/api_providers.dart';
import '../widgets/pitwall_widgets.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String selectedDriver = 'VER';
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(driverSeasonProvider([selectedYear, selectedDriver]));

    return Scaffold(
      appBar: AppBar(
        title: Text('DRIVER ANALYTICS', style: AppConfig.displayStyle.copyWith(fontSize: 18)),
      ),
      body: Column(
        children: [
          _buildSelectors(),
          Expanded(
            child: seasonAsync.when(
              data: (data) => _buildStatsDashboard(data),
              loading: () => const Center(child: CircularProgressIndicator(color: AppConfig.accentRed)),
              error: (err, stack) => const Center(child: Text('Season stats unavailable')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppConfig.card, borderRadius: BorderRadius.circular(4)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDriver,
                  items: ['VER', 'NOR', 'LEC', 'HAM', 'SAI', 'PIA', 'RUS', 'PER', 'ALO']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: AppConfig.monoStyle))).toList(),
                  onChanged: (v) => setState(() => selectedDriver = v!),
                  dropdownColor: AppConfig.card,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(Map<String, dynamic> data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _statCard('TOTAL POINTS', data['total_points'].toString()),
            const SizedBox(width: 12),
            _statCard('WINS', data['wins'].toString()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard('PODIUMS', data['podiums'].toString()),
            const SizedBox(width: 12),
            _statCard('AVG FINISH', data['avg_finish'].toString()),
          ],
        ),
        const SizedBox(height: 24),
        Text('CHAMPIONSHIP EVOLUTION', style: AppConfig.displayStyle.copyWith(fontSize: 12, color: Colors.white24)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PitwallCard(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: (data['evolution'] as List).asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                    color: AppConfig.accentRed,
                    isCurved: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: PitwallCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white24)),
            Text(value, style: AppConfig.displayStyle.copyWith(fontSize: 24, color: AppConfig.accentGold)),
          ],
        ),
      ),
    );
  }
}
