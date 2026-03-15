import 'package:flutter/material.dart';

import '../services/alarm_ring_flow.dart';
import '../services/alarm_service.dart';

class AlarmRingScreen extends StatelessWidget {
  const AlarmRingScreen({super.key});

  static const routeName = '/alarm-ring';

  @override
  Widget build(BuildContext context) {
    final alarmId = (ModalRoute.of(context)?.settings.arguments as int?) ?? 0;
    final alarm = AlarmService.findByIntId(alarmId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                alarm?.timeLabel ?? '06:30',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 90,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                alarm?.periodLabel ?? 'AM',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 52,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                alarm?.label ?? 'Work Morning',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 28,
                  color: const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '⚡ ${alarm?.aiTag ?? 'Optimal sleep cycle'} · ${alarm?.repeatLabel ?? 'Weekdays'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF475467),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF4B5563), width: 2),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 52),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'SWIPE UP TO DISMISS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 3,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => AlarmRingFlow.snoozeAlarm(alarmId),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(62),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text('Snooze · 5 min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AlarmRingFlow.stopAlarm(alarmId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(62),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text('Stop Alarm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
