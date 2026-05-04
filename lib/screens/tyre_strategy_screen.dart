import 'package:flutter/material.dart';
import '../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';

class StintData {
  final String driverCode;
  final List<TyreStint> stints;

  StintData(this.driverCode, this.stints);
}

class TyreStint {
  final String compound; // Soft, Medium, Hard, Inter, Wet
  final int startLap;
  final int endLap;

  TyreStint(this.compound, this.startLap, this.endLap);
}

class TyreStrategyScreen extends StatelessWidget {
  TyreStrategyScreen({super.key});

  final List<StintData> strategyData = [
    StintData('VER', [
      TyreStint('Soft', 1, 15),
      TyreStint('Medium', 15, 38),
      TyreStint('Medium', 38, 57),
    ]),
    StintData('PER', [
      TyreStint('Soft', 1, 14),
      TyreStint('Hard', 14, 40),
      TyreStint('Soft', 40, 57),
    ]),
    StintData('LEC', [
      TyreStint('Soft', 1, 13),
      TyreStint('Hard', 13, 35),
      TyreStint('Hard', 35, 57),
    ]),
    StintData('SAI', [
      TyreStint('Medium', 1, 18),
      TyreStint('Hard', 18, 42),
      TyreStint('Soft', 42, 57),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tyre Strategy — Bahrain GP',
            style: PitwallTheme.monoStyle.copyWith(fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PitwallCard(
          child: Column(
            children: [
              _buildHeader(),
              const Divider(color: PitwallTheme.cardBorder, height: 32),
              ...strategyData.map((data) => _buildDriverRow(data)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _compoundIndicator('Soft', Colors.red),
        _compoundIndicator('Medium', Colors.yellow),
        _compoundIndicator('Hard', Colors.grey),
        _compoundIndicator('Inter', Colors.green),
      ],
    );
  }

  Widget _compoundIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDriverRow(StintData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              data.driverCode,
              style: PitwallTheme.monoStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 24,
              child: Stack(
                children: [
                  // Timeline background
                  Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Stints
                  ...data.stints.map((stint) => _buildStintBar(stint)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStintBar(TyreStint stint) {
    // Basic calculation for width based on 57 laps total
    final start = stint.startLap / 57.0;
    final end = stint.endLap / 57.0;
    final color = _getColorForCompound(stint.compound);

    return Positioned(
      left: 0,
      right: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.only(
              left: constraints.maxWidth * start,
              right: constraints.maxWidth * (1 - end),
            ),
            child: Container(
              height: 12,
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getColorForCompound(String compound) {
    switch (compound) {
      case 'Soft': return Colors.red;
      case 'Medium': return Colors.yellow;
      case 'Hard': return Colors.grey;
      case 'Inter': return Colors.green;
      case 'Wet': return Colors.blue;
      default: return Colors.white;
    }
  }
}
