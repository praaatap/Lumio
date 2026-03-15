import 'package:flutter/material.dart';

import '../models/alarm_model.dart';
import 'ai_chip.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({super.key, required this.alarm, required this.onToggle});

  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final color = alarm.isEnabled
        ? const Color(0xFF0F172A)
        : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 66,
                    fontWeight: FontWeight.w400,
                    color: color,
                    height: 0.95,
                  ),
                  children: [
                    TextSpan(text: alarm.timeLabel),
                    TextSpan(
                      text: ' ${alarm.periodLabel}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.w400,
                        color: color.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Switch(
                value: alarm.isEnabled,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF22C55E),
                inactiveThumbColor: const Color(0xFFE2E8F0),
                inactiveTrackColor: const Color(0xFFF1F5F9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AiChip(
                label: alarm.aiTag,
                icon: alarm.aiTag.toLowerCase().contains('sleep')
                    ? Icons.bolt_rounded
                    : Icons.auto_awesome_rounded,
              ),
              const SizedBox(width: 12),
              Text(
                alarm.repeatLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
