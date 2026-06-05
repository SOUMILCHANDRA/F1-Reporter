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
  const ResultsTab({
    super.key,
    required this.year,
    required this.round,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(resultsProvider((year, round, session)));

    return resultsAsync.when(
      data: (data) {
        if (data.isEmpty)
          return const Center(child: Text('NO RESULTS DATA AVAILABLE'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final r = data[index];
            final teamColor = _hexToColor(r['team_color']);
            return PitwallCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Text(
                  r['position']?.toString() ?? '-',
                  style: AppConfig.displayStyle.copyWith(fontSize: 18),
                ),
                title: Text(
                  r['full_name'] ?? 'Unknown Driver',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  r['team']?.toString().toUpperCase() ?? 'PRIVATEER',
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(r),
                      style: AppConfig.monoStyle.copyWith(fontSize: 11),
                    ),
                    if (r['points'] != null && r['points'] > 0)
                      Text(
                        '+${r['points']} PTS',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppConfig.accentGold,
                        ),
                      ),
                  ],
                ),
                tileColor: Colors.transparent,
                onTap: () => _showDriverDetail(context, r),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppConfig.accentRed),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppConfig.accentRed,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Results not available',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              err.toString(),
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverDetail(BuildContext context, dynamic driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConfig.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              driver['full_name']?.toString().toUpperCase() ?? 'DRIVER',
              style: AppConfig.displayStyle.copyWith(fontSize: 20),
            ),
            Text(
              driver['team'] ?? 'Team',
              style: TextStyle(
                color: _hexToColor(driver['team_color']),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 32, color: AppConfig.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailStat(
                  'GRID',
                  driver['grid_position']?.toString() ?? 'N/A',
                ),
                _detailStat('FINISH', driver['position']?.toString() ?? 'N/A'),
                _detailStat('POINTS', driver['points']?.toString() ?? '0'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.accentRed,
                ),
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
        Text(
          label,
          style: const TextStyle(color: Colors.white24, fontSize: 10),
        ),
        Text(
          value,
          style: AppConfig.monoStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic r) {
    if (r['position'] == 1 && r['finishing_time'] != null) {
      return _durationToString(r['finishing_time'] as num?);
    }
    final gap = r['gap_to_leader'];
    if (gap != null && gap is num && gap > 0) {
      if (gap > 60000) return '+${_durationToString(gap)}';
      return '+${(gap / 1000).toStringAsFixed(3)}';
    }
    return r['status']?.toString() ?? 'N/A';
  }
}

// --- TELEMETRY TAB ---
class TelemetryTab extends ConsumerStatefulWidget {
  final int year, round;
  final String session;
  const TelemetryTab({
    super.key,
    required this.year,
    required this.round,
    required this.session,
  });

  @override
  ConsumerState<TelemetryTab> createState() => _TelemetryTabState();
}

class _TelemetryTabState extends ConsumerState<TelemetryTab> {
  String? driver1;
  String? driver2;

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(
      resultsProvider((widget.year, widget.round, widget.session)),
    );

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty)
          return const Center(child: Text('NO DRIVERS AVAILABLE'));

        final drivers = results
            .map((r) => r['driver_code']?.toString() ?? '???')
            .toList();
        driver1 ??= drivers.first;
        driver2 ??= drivers.length > 1 ? drivers[1] : drivers.first;

        final t1Async = ref.watch(
          telemetryProvider((
            widget.year,
            widget.round,
            widget.session,
            driver1!,
          )),
        );
        final t2Async = ref.watch(
          telemetryProvider((
            widget.year,
            widget.round,
            widget.session,
            driver2!,
          )),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDriverSelectors(drivers),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: t1Async.when(
                  data: (d1) => t2Async.when(
                    data: (d2) {
                      final s1 = d1['speed'] as List?;
                      final s2 = d2['speed'] as List?;
                      if ((s1 == null || s1.isEmpty) &&
                          (s2 == null || s2.isEmpty)) {
                        return const Center(
                          child: Text('NO TELEMETRY DATA AVAILABLE'),
                        );
                      }
                      return _buildTelemetryChart(d1, d2);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) =>
                        const Center(child: Text('Compare Data Error')),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('Telemetry Error')),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Drivers list unavailable: $err')),
    );
  }

  Widget _buildDriverSelectors(List<String> drivers) {
    return Row(
      children: [
        Expanded(
          child: _driverDropdown(
            driver1!,
            drivers,
            (v) => setState(() => driver1 = v),
          ),
        ),
        const SizedBox(width: 16),
        const Text('VS', style: TextStyle(color: Colors.white24)),
        const SizedBox(width: 16),
        Expanded(
          child: _driverDropdown(
            driver2!,
            drivers,
            (v) => setState(() => driver2 = v),
          ),
        ),
      ],
    );
  }

  Widget _driverDropdown(
    String value,
    List<String> drivers,
    ValueChanged<String?>? onChange,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppConfig.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppConfig.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: drivers.contains(value) ? value : drivers.first,
          items: drivers
              .map(
                (d) => DropdownMenuItem(
                  value: d,
                  child: Text(d, style: AppConfig.monoStyle),
                ),
              )
              .toList(),
          onChanged: onChange,
          dropdownColor: AppConfig.card,
        ),
      ),
    );
  }

  Widget _buildTelemetryChart(
    Map<String, dynamic> d1,
    Map<String, dynamic> d2,
  ) {
    final speed1 = d1['speed'] as List?;
    final speed2 = d2['speed'] as List?;

    final spots1 = speed1 != null
        ? speed1
              .asMap()
              .entries
              .map(
                (e) => FlSpot(
                  e.key.toDouble(),
                  (e.value as num?)?.toDouble() ?? 0.0,
                ),
              )
              .toList()
        : <FlSpot>[];
    final spots2 = speed2 != null
        ? speed2
              .asMap()
              .entries
              .map(
                (e) => FlSpot(
                  e.key.toDouble(),
                  (e.value as num?)?.toDouble() ?? 0.0,
                ),
              )
              .toList()
        : <FlSpot>[];

    return PitwallCard(
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots1,
              color: Colors.blue,
              barWidth: 1,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spots2,
              color: Colors.orange,
              barWidth: 1,
              dotData: const FlDotData(show: false),
            ),
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
  const TyresTab({
    super.key,
    required this.year,
    required this.round,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategyAsync = ref.watch(tyreStrategyProvider((year, round)));

    return strategyAsync.when(
      data: (data) {
        if (data.isEmpty)
          return const Center(child: Text('NO STRATEGY DATA AVAILABLE'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final driver = data[index];
            final List stints = driver['stints'] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      driver['driver_code'] ?? '???',
                      style: AppConfig.monoStyle.copyWith(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: stints
                            .map(
                              (s) => Expanded(
                                flex: (s['lap_count'] as num?)?.toInt() ?? 1,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCompoundColor(
                                      s['compound']?.toString() ?? 'UNKNOWN',
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Tyre strategy not available: $err')),
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
  const WeatherTab({
    super.key,
    required this.year,
    required this.round,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider((year, round, session)));

    return weatherAsync.when(
      data: (data) {
        if ((data.isEmpty))
          return const Center(child: Text('NO WEATHER DATA AVAILABLE'));
        final airTemp = data['air_temp'] ?? 'N/A';
        final trackTemp = data['track_temp'] ?? 'N/A';
        final humidity = data['humidity'] ?? 'N/A';
        final windSpeed = data['wind_speed'] ?? 'N/A';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  _weatherCard('AIR TEMP', '$airTemp°C', Icons.thermostat),
                  const SizedBox(width: 12),
                  _weatherCard('TRACK TEMP', '$trackTemp°C', Icons.add_road),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _weatherCard('HUMIDITY', '$humidity%', Icons.water_drop),
                  const SizedBox(width: 12),
                  _weatherCard('WIND SPEED', '$windSpeed KPH', Icons.air),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Weather not available: $err')),
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
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white24),
            ),
            Text(
              value,
              style: AppConfig.monoStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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
  const RaceControlTab({
    super.key,
    required this.year,
    required this.round,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rcAsync = ref.watch(raceControlProvider((year, round)));

    return rcAsync.when(
      data: (data) {
        if (data.isEmpty)
          return const Center(child: Text('NO RACE CONTROL MESSAGES'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final msg = data[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConfig.card,
                border: Border(
                  left: BorderSide(
                    color: _getRCColor(msg['category']),
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LAP ${msg['lap'] ?? 'N/A'}',
                        style: AppConfig.monoStyle.copyWith(
                          fontSize: 10,
                          color: AppConfig.accentRed,
                        ),
                      ),
                      Text(
                        msg['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg['message'] ?? '---',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Race Control not available: $err')),
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

class LapsTab extends ConsumerWidget {
  final int year, round;
  final String session;
  const LapsTab({
    super.key,
    required this.year,
    required this.round,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapsAsync = ref.watch(lapsProvider((year, round, session)));

    return lapsAsync.when(
      data: (data) {
        if (data.isEmpty)
          return const Center(child: Text('NO LAP DATA AVAILABLE'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final driver = data[index];
            final List laps = driver['laps'] ?? [];
            final lastLap = laps.isNotEmpty ? laps.last : null;

            return PitwallCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      driver['driver_code'] ?? '???',
                      style: AppConfig.monoStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAPS COMPLETED: ${laps.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (lastLap != null && lastLap['lap_time_ms'] != null)
                          Text(
                            'LAST: ${_durationToString(lastLap['lap_time_ms'])}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white24,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (laps.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STINT ${laps.last['stint'] ?? 1}',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppConfig.accentRed),
      ),
      error: (err, _) => Center(child: Text('Lap data unavailable: $err')),
    );
  }
}

// --- FASTEST LAPS TAB ---
class FastestLapsTab extends ConsumerWidget {
  final int year, round;
  final String sessionName;
  const FastestLapsTab({
    super.key,
    required this.year,
    required this.round,
    required this.sessionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(resultsProvider((year, round, sessionName)));

    return resultsAsync.when(
      data: (data) {
        if (data.isEmpty)
          return const Center(child: Text('NO DATA FOR THIS SESSION'));
        final fastest = data
            .where((r) => r['fastest_lap_time'] != null)
            .toList();
        fastest.sort(
          (a, b) => (a['fastest_lap_time'] as num).compareTo(
            b['fastest_lap_time'] as num,
          ),
        );

        if (fastest.isEmpty)
          return const Center(child: Text('NO FASTEST LAPS RECORDED'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fastest.length,
          itemBuilder: (context, index) {
            final r = fastest[index];
            return PitwallCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  '${index + 1}',
                  style: AppConfig.displayStyle.copyWith(
                    fontSize: 16,
                    color: index == 0 ? AppConfig.accentGold : Colors.white,
                  ),
                ),
                title: Text(r['full_name'] ?? 'Unknown'),
                trailing: Text(
                  _durationToString(r['fastest_lap_time']),
                  style: AppConfig.monoStyle.copyWith(
                    color: AppConfig.accentRed,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Fastest lap data unavailable: $err')),
    );
  }
}

// --- PIT STOPS TAB ---
class PitStopsTab extends ConsumerWidget {
  final int year, round;
  final String session;
  const PitStopsTab({
    super.key,
    required this.year,
    required this.round,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapsAsync = ref.watch(lapsProvider((year, round, session)));

    return lapsAsync.when(
      data: (data) {
        if (data.isEmpty)
          return const Center(child: Text('NO PIT STOP DATA AVAILABLE'));
        final List pitStops = [];
        for (var driver in data) {
          final List laps = driver['laps'] ?? [];
          for (var lap in laps) {
            if (lap['pit_in_time'] != null || lap['pit_out_time'] != null) {
              pitStops.add({
                'driver_code': driver['driver_code'],
                'lap': lap['lap_number'],
                'time': lap['pit_in_time'] ?? lap['pit_out_time'],
              });
            }
          }
        }
        pitStops.sort((a, b) => (a['lap'] as int).compareTo(b['lap'] as int));

        if (pitStops.isEmpty)
          return const Center(child: Text('NO PIT STOPS RECORDED'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pitStops.length,
          itemBuilder: (context, index) {
            final p = pitStops[index];
            return PitwallCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p['driver_code'] ?? '???',
                    style: AppConfig.monoStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('LAP ${p['lap'] ?? '-'}'),
                  Text(
                    'IN AT: ${p['time'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Pit stop data unavailable: $err')),
    );
  }
}

// Global helpers
String _durationToString(num? ms) {
  if (ms == null) return 'N/A';
  final duration = Duration(milliseconds: ms.toInt());
  final h = duration.inHours;
  final m = duration.inMinutes.remainder(60);
  final s = duration.inSeconds.remainder(60);
  final mm = ms.toInt().remainder(1000);

  if (h > 0)
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${mm.toString().padLeft(3, '0')}';
  return '$m:${s.toString().padLeft(2, '0')}.${mm.toString().padLeft(3, '0')}';
}

Color _hexToColor(String? hex) {
  if (hex == null) return Colors.white24;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return Colors.white24;
  }
}
