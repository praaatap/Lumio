import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alarm_model.dart';
import '../services/alarm_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsListProvider);

    return SafeArea(
      child: alarmsAsync.when(
        data: (alarms) {
          final insightData = _buildInsightData(alarms);
          final alarmsContext = _buildAlarmsContext(alarms, insightData.focusText);
          final aiInsightAsync = ref.watch(aiSuggestionProvider(
            'Rewrite this as one short productivity insight: ${insightData.focusText}. '
            'Context: $alarmsContext',
          ));

          return ListView(
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
                            final index = value.toInt();
                            if (index < 0 || index >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[index],
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
                      insightData.bars.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: insightData.bars[index],
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
              _HeatMap(values: insightData.heatValues),
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
                        aiInsightAsync.maybeWhen(
                          data: (value) => value,
                          orElse: () => insightData.focusText,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  _InsightData _buildInsightData(List<AlarmModel> alarms) {
    final enabledAlarms = alarms.where((alarm) => alarm.isEnabled).toList();
    final dayCounts = List<double>.filled(7, 0);

    for (final alarm in enabledAlarms) {
      if (alarm.repeatDays.isEmpty) {
        final dayIndex = alarm.nextDateTimeFrom(DateTime.now()).weekday - 1;
        dayCounts[dayIndex] += 1;
      } else {
        for (final day in alarm.repeatDays) {
          dayCounts[day - 1] += 1;
        }
      }
    }

    final maxCount = dayCounts.reduce((a, b) => a > b ? a : b);
    final bars = dayCounts
        .map((count) => maxCount == 0 ? 20.0 : 20 + ((count / maxCount) * 72))
        .toList();

    final heatValues = List<int>.generate(28, (index) {
      final dayIndex = index % 7;
      final intensity = maxCount == 0 ? 0 : (dayCounts[dayIndex] / maxCount) * 4;
      return intensity.round().clamp(0, 4);
    });

    final focusText = _buildFocusText(enabledAlarms, dayCounts);
    return _InsightData(bars: bars, heatValues: heatValues, focusText: focusText);
  }

  String _buildFocusText(List<AlarmModel> alarms, List<double> dayCounts) {
    if (alarms.isEmpty) {
      return 'Add and enable alarms to unlock personalized focus insights.';
    }

    var totalMinutes = 0;
    for (final alarm in alarms) {
      totalMinutes += (alarm.time.hour * 60) + alarm.time.minute;
    }
    final avgMinutes = (totalMinutes / alarms.length).round();
    final avgHour = avgMinutes ~/ 60;
    final avgMinute = avgMinutes % 60;

    var bestDayIndex = 0;
    var bestDayValue = dayCounts[0];
    for (var i = 1; i < dayCounts.length; i++) {
      if (dayCounts[i] > bestDayValue) {
        bestDayValue = dayCounts[i];
        bestDayIndex = i;
      }
    }

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hh = avgHour == 0 ? 12 : (avgHour > 12 ? avgHour - 12 : avgHour);
    final mm = avgMinute.toString().padLeft(2, '0');
    final period = avgHour >= 12 ? 'PM' : 'AM';

    return 'Most alarms cluster on ${dayLabels[bestDayIndex]} around $hh:$mm $period.';
  }

  String _buildAlarmsContext(List<AlarmModel> alarms, String fallbackInsight) {
    if (alarms.isEmpty) {
      return 'No alarms configured.';
    }

    final enabledCount = alarms.where((alarm) => alarm.isEnabled).length;
    return 'Total alarms: ${alarms.length}, enabled: $enabledCount, baseline insight: $fallbackInsight';
  }
}

class _HeatMap extends StatelessWidget {
  const _HeatMap({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final shades = [
      const Color(0xFF000000),
      const Color(0xFF5B5B5B),
      const Color(0xFF808080),
      const Color(0xFFB0B0B0),
      const Color(0xFFD4D4D4),
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

class _InsightData {
  const _InsightData({
    required this.bars,
    required this.heatValues,
    required this.focusText,
  });

  final List<double> bars;
  final List<int> heatValues;
  final String focusText;
}
