import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bars = [42.0, 58.0, 76.0, 92.0, 28.0, 20.0, 20.0];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        children: [
          Text(
            'YOUR WEEK',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 3,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text('Insights', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt()],
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(letterSpacing: 1.8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  bars.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bars[index],
                        width: 16,
                        color: index < 4
                            ? Colors.black
                            : const Color(0xFFD4D7DD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'FOCUS INTENSITY',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 3,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          const _HeatMap(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x070F172A),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You focus best between 9 AM - 11 AM.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatMap extends StatelessWidget {
  const _HeatMap();

  @override
  Widget build(BuildContext context) {
    final shades = [
      const Color(0xFF000000),
      const Color(0xFF5B5B5B),
      const Color(0xFF808080),
      const Color(0xFFB0B0B0),
      const Color(0xFFD4D4D4),
    ];

    final values = [
      0,
      2,
      4,
      3,
      0,
      4,
      1,
      4,
      3,
      4,
      0,
      2,
      4,
      0,
      0,
      1,
      0,
      4,
      2,
      0,
      4,
      4,
      4,
      2,
      0,
      3,
      4,
      0,
    ];

    return GridView.builder(
      itemCount: values.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: shades[values[index]],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
