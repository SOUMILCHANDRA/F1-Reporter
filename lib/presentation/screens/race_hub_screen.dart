import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';

class RaceHubScreen extends StatefulWidget {
  const RaceHubScreen({super.key});

  @override
  State<RaceHubScreen> createState() => _RaceHubScreenState();
}

class _RaceHubScreenState extends State<RaceHubScreen> {
  final List<String> tabs = [
    'Results', 'Laps', 'Tyres', 'Positions', 'Telemetry', 'Weather', 'RC', 'Fastest', 'Pits'
  ];
  String selectedTab = 'Laps';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.arrow_drop_down, color: Colors.white),
            const SizedBox(width: 4),
            Text('2024 / Round 01 / Bahrain GP',
                style: PitwallTheme.monoStyle.copyWith(fontSize: 14)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSubTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLapTimeChart(),
                  const SizedBox(height: 24),
                  _buildDriverLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PitwallTheme.cardBorder, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = selectedTab == tab;
          return GestureDetector(
            onTap: () => setState(() => selectedTab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? PitwallTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLapTimeChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: PitwallCard(
          padding: const EdgeInsets.all(12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: PitwallTheme.cardBorder,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => const FlLine(
                  color: PitwallTheme.cardBorder,
                  strokeWidth: 1,
                ),
              ),
              titlesData: const FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 10,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: PitwallTheme.cardBorder),
              ),
              lineBarsData: [
                _lineData(PitwallTheme.teamRedBull, [
                  const FlSpot(1, 91.2), const FlSpot(10, 90.8), const FlSpot(20, 91.5), 
                  const FlSpot(30, 90.5), const FlSpot(40, 90.2), const FlSpot(50, 89.8)
                ]),
                _lineData(PitwallTheme.teamFerrari, [
                  const FlSpot(1, 91.5), const FlSpot(10, 91.2), const FlSpot(20, 92.1), 
                  const FlSpot(30, 91.8), const FlSpot(40, 91.4), const FlSpot(50, 90.5)
                ]),
                _lineData(PitwallTheme.teamMercedes, [
                  const FlSpot(1, 91.8), const FlSpot(10, 91.5), const FlSpot(20, 91.8), 
                  const FlSpot(30, 92.2), const FlSpot(40, 92.0), const FlSpot(50, 91.2)
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineData(Color color, List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildDriverLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _legendItem('VER', PitwallTheme.teamRedBull),
          _legendItem('LEC', PitwallTheme.teamFerrari),
          _legendItem('HAM', PitwallTheme.teamMercedes),
          _legendItem('NOR', PitwallTheme.teamMcLaren),
          _legendItem('ALO', PitwallTheme.teamAstonMartin),
        ],
      ),
    );
  }

  Widget _legendItem(String code, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PitwallTheme.cardBackground,
        border: Border.all(color: PitwallTheme.cardBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            code,
            style: PitwallTheme.monoStyle.copyWith(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
