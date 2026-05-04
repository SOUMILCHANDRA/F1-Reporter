import 'package:flutter/material.dart';
import '../theme/pitwall_theme.dart';
import '../widgets/pitwall_widgets.dart';

class DriverDetailSheet extends StatelessWidget {
  const DriverDetailSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DriverDetailSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PitwallTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: PitwallTheme.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('MAX VERSTAPPEN', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24)),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: TeamBadge(teamName: 'Red Bull Racing', teamColor: PitwallTheme.teamRedBull),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 2, width: 100, color: PitwallTheme.teamRedBull),
          const SizedBox(height: 32),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildStatCard('GRID', 'P1'),
              _buildStatCard('FINISH', 'P1'),
              _buildStatCard('GAP', '+0.000'),
              _buildStatCard('POINTS', '+25'),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text('SEASON TOTALS', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTotalItem('POINTS', '454'),
              _buildTotalItem('WINS', '15'),
              _buildTotalItem('PODIUMS', '18'),
            ],
          ),
          
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: PitwallTheme.primaryAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('FULL SEASON STATS →', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PitwallTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PitwallTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          TimingText(value, fontSize: 16, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
