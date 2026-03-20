import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/alarm_service.dart';
import '../services/alarm_providers.dart';
import '../services/smart_alarm_service.dart';
import '../widgets/alarm_card.dart';
import '../widgets/ai_chip.dart';
import 'ai_chat_screen.dart';
import 'alarms_screen.dart';
import 'focus_timer_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsListProvider);

    return SafeArea(
      child: alarmsAsync.when(
        data: (alarms) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
        children:
            [
                  Row(
                    children: [
                      Text(
                        '✦ FlowMind',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AlarmsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 34),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'YOUR TODAY',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(letterSpacing: 2.8),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
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
                    child: Column(
                      children: [
                        _TimelineTile(
                          time: '09:00',
                          title: 'Deep Work Block',
                          subtitle: '25 min focus sprint',
                        ),
                        _TimelineTile(
                          time: '10:30',
                          title: 'Review + Notes',
                          subtitle: 'AI-assisted summary session',
                        ),
                        _TimelineTile(
                          time: '11:15',
                          title: 'Suggested break',
                          subtitle: 'Based on your current rhythm',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Text(
                        'UPCOMING ALARMS',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(letterSpacing: 2.8),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AlarmsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'View all',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...alarms
                      .take(2)
                      .map(
                        (alarm) => AlarmCard(
                          alarm: alarm,
                          onToggle: (value) =>
                              ref.read(alarmsMapProvider.notifier).toggleAlarm(alarm.id, value),
                        ),
                      ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFF3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Suggestion',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Based on your activity, 11:15 PM is your best bedtime.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              const AiChip(label: 'AI bedtime optimized'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood + Sleep Check-In',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Quick daily check-in can auto-adjust your next alarm.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showMoodCheckIn(context),
                                child: const Text('Check In'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Wind-down: ${SmartAlarmService.windDownChecklist().first}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AiChatScreen.routeName);
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Open AI Assistant'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(FocusTimerScreen.routeName);
                          },
                          icon: const Icon(Icons.timer_outlined),
                          label: const Text('Start Focus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
                .animate(interval: 70.ms)
                .fadeIn(duration: 240.ms)
                .move(begin: const Offset(0, 8), end: Offset.zero),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _showMoodCheckIn(BuildContext context) async {
    var energy = 3.0;
    var mood = 3.0;
    var sleep = 3.0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Morning Check-In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sliderRow('Energy', energy, (v) => setState(() => energy = v)),
              _sliderRow('Mood', mood, (v) => setState(() => mood = v)),
              _sliderRow('Sleep', sleep, (v) => setState(() => sleep = v)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      return;
    }

    await SmartAlarmService.saveMoodCheckIn(
      energy: energy.round(),
      mood: mood.round(),
      sleepQuality: sleep.round(),
    );
    await AlarmService.autoAdjustNextAlarmFromMood(
      energy: energy.round(),
      sleepQuality: sleep.round(),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in saved. Next alarm tuned.')),
    );
  }

  Widget _sliderRow(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()} / 5'),
        Slider(value: value, min: 1, max: 5, divisions: 4, onChanged: onChanged),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.time,
    required this.title,
    required this.subtitle,
  });

  final String time;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 14),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
