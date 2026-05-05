import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_config.dart';
import '../providers/api_providers.dart';
import 'pitwall_widgets.dart';

// --- RESULTS TAB ---
class ResultsTab extends ConsumerWidget {
  final int year, round;
  final String session;
  const ResultsTab({super.key, required this.year, required this.round, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(resultsProvider([year, round, session]));

    return resultsAsync.when(
      data: (data) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final r = data[index];
          final teamColor = _hexToColor(r['team_color']);
          return PitwallCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Text(r['position'].toString(), style: AppConfig.displayStyle.copyWith(fontSize: 18)),
              title: Text(r['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(r['team'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white60)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(r['time'] ?? r['status'], style: AppConfig.monoStyle.copyWith(fontSize: 11)),
                  if (r['points'] > 0) Text('+${r['points']} PTS', style: const TextStyle(fontSize: 10, color: AppConfig.accentGold)),
                ],
              ),
              tileColor: Colors.transparent,
              onTap: () => _showDriverDetail(context, r),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppConfig.accentRed)),
      error: (_, __) => const Center(child: Text('Results not available')),
    );
  }

  void _showDriverDetail(BuildContext context, dynamic driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConfig.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver['full_name'].toString().toUpperCase(), style: AppConfig.displayStyle.copyWith(fontSize: 20)),
            Text(driver['team'], style: TextStyle(color: _hexToColor(driver['team_color']), fontWeight: FontWeight.bold)),
            const Divider(height: 32, color: AppConfig.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailStat('GRID', driver['grid_position']?.toString() ?? 'N/A'),
                _detailStat('FINISH', driver['position'].toString()),
                _detailStat('POINTS', driver['points'].toString()),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.accentRed),
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        Text(value, style: AppConfig.monoStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- TELEMETRY TAB ---
class TelemetryTab extends ConsumerStatefulWidget {
  final int year, round;
  final String session;
  const TelemetryTab({super.key, required this.year, required this.round, required this.session});

  @override
  ConsumerState<TelemetryTab> createState() => _TelemetryTabState();
}

class _TelemetryTabState extends ConsumerState<TelemetryTab> {
  String driver1 = 'VER';
  String driver2 = 'NOR';

  @override
  Widget build(BuildContext context) {
    final t1Async = ref.watch(telemetryProvider([widget.year, widget.round, widget.session, driver1]));
    final t2Async = ref.watch(telemetryProvider([widget.year, widget.round, widget.session, driver2]));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDriverSelectors(),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: t1Async.when(
              data: (d1) => t2Async.when(
                data: (d2) => _buildTelemetryChart(d1, d2),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Compare Data Error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Telemetry Error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSelectors() {
    return Row(
      children: [
        Expanded(child: _driverDropdown(driver1, (v) => setState(() => driver1 = v!))),
        const SizedBox(width: 16),
        const Text('VS', style: TextStyle(color: Colors.white24)),
        const SizedBox(width: 16),
        Expanded(child: _driverDropdown(driver2, (v) => setState(() => driver2 = v!))),
      ],
    );
  }

  Widget _driverDropdown(String value, ValueChanged<String?>? onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppConfig.card, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppConfig.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: ['VER', 'NOR', 'LEC', 'HAM', 'SAI', 'PIA', 'RUS', 'PER', 'ALO', 'STR']
              .map((d) => DropdownMenuItem(value: d, child: Text(d, style: AppConfig.monoStyle))).toList(),
          onChanged: onChange,
          dropdownColor: AppConfig.card,
        ),
      ),
    );
  }

  Widget _buildTelemetryChart(Map<String, dynamic> d1, Map<String, dynamic> d2) {
    final speed1 = d1['speed'] as List?;
    final speed2 = d2['speed'] as List?;
    
    final spots1 = speed1 != null 
        ? speed1.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList()
        : <FlSpot>[];
    final spots2 = speed2 != null 
        ? speed2.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList()
        : <FlSpot>[];

    return PitwallCard(
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(spots: spots1, color: Colors.blue, barWidth: 1, dotData: const FlDotData(show: false)),
            LineChartBarData(spots: spots2, color: Colors.orange, barWidth: 1, dotData: const FlDotData(show: false)),
          ],
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

// --- TYRES TAB ---
class TyresTab extends ConsumerWidget {
  final int year, round;
  final String session;
  const TyresTab({super.key, required this.year, required this.round, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategyAsync = ref.watch(tyreStrategyProvider([year, round]));

    return strategyAsync.when(
      data: (data) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final driver = data[index];
          final List stints = driver['stints'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text(driver['driver_code'], style: AppConfig.monoStyle.copyWith(fontSize: 11))),
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                    child: Row(
                      children: stints.map((s) => Expanded(
                        flex: s['lap_count'] as int,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(color: _getCompoundColor(s['compound']), borderRadius: BorderRadius.circular(1)),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Tyre strategy not available')),
    );
  }

  Color _getCompoundColor(String c) {
    c = c.toUpperCase();
    if (c.contains('SOFT')) return Colors.red;
    if (c.contains('MEDIUM')) return Colors.yellow;
    if (c.contains('HARD')) return Colors.white;
    if (c.contains('INTER')) return Colors.green;
    return Colors.blue;
  }
}

// --- WEATHER TAB ---
class WeatherTab extends ConsumerWidget {
  final int year, round;
  final String session;
  const WeatherTab({super.key, required this.year, required this.round, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider([year, round, session]));

    return weatherAsync.when(
      data: (data) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _weatherCard('AIR TEMP', '${data['air_temp']}°C', Icons.thermostat),
                const SizedBox(width: 12),
                _weatherCard('TRACK TEMP', '${data['track_temp']}°C', Icons.add_road),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _weatherCard('HUMIDITY', '${data['humidity']}%', Icons.water_drop),
                const SizedBox(width: 12),
                _weatherCard('WIND SPEED', '${data['wind_speed']} KPH', Icons.air),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Weather not available')),
    );
  }

  Widget _weatherCard(String label, String value, IconData icon) {
    return Expanded(
      child: PitwallCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppConfig.accentRed, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white24)),
            Text(value, style: AppConfig.monoStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- RACE CONTROL TAB ---
class RaceControlTab extends ConsumerWidget {
  final int year, round;
  final String session;
  const RaceControlTab({super.key, required this.year, required this.round, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rcAsync = ref.watch(raceControlProvider([year, round]));

    return rcAsync.when(
      data: (data) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final msg = data[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppConfig.card, border: Border(left: BorderSide(color: _getRCColor(msg['category']), width: 4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LAP ${msg['lap'] ?? 'N/A'}', style: AppConfig.monoStyle.copyWith(fontSize: 10, color: AppConfig.accentRed)),
                    Text(msg['time'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(msg['message'], style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Race Control not available')),
    );
  }

  Color _getRCColor(String? cat) {
    cat = cat?.toLowerCase() ?? '';
    if (cat.contains('yellow')) return Colors.yellow;
    if (cat.contains('red')) return Colors.red;
    if (cat.contains('safety')) return Colors.orange;
    if (cat.contains('green')) return Colors.green;
    return AppConfig.border;
  }
}

// Helpers
Color _hexToColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return Colors.white24;
  }
}

// LapsTab placeholder
class LapsTab extends StatelessWidget {
  final int year, round;
  final String session;
  const LapsTab({super.key, required this.year, required this.round, required this.session});
  @override
  Widget build(BuildContext context) => const Center(child: Text('LAP DATA STREAMING...'));
}
