import 'package:flutter/material.dart';

import '../services/alarm_ring_flow.dart';
import '../services/alarm_service.dart';
import '../services/smart_alarm_service.dart';

class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key});

  static const routeName = '/alarm-ring';

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  DismissChallengeType _challengeType = DismissChallengeType.none;

  @override
  void initState() {
    super.initState();
    SmartAlarmService.getDismissChallenge().then((value) {
      if (!mounted) return;
      setState(() => _challengeType = value);
    });
  }

  Future<void> _stopWithChallenge(int alarmId) async {
    final allowed = await _solveChallenge();
    if (!allowed) {
      return;
    }
    await AlarmRingFlow.stopAlarm(alarmId);
  }

  Future<bool> _solveChallenge() async {
    if (_challengeType == DismissChallengeType.none) {
      return true;
    }

    switch (_challengeType) {
      case DismissChallengeType.math:
        return _showMathChallenge();
      case DismissChallengeType.memory:
        return _showMemoryChallenge();
      case DismissChallengeType.qr:
        return _showQrPlaceholderChallenge();
      case DismissChallengeType.steps:
        return _showStepsChallenge();
      case DismissChallengeType.none:
        return true;
    }
  }

  Future<bool> _showMathChallenge() async {
    final a = (DateTime.now().millisecond % 8) + 3;
    final b = (DateTime.now().second % 8) + 2;
    final answerController = TextEditingController();

    final solved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Math Challenge'),
        content: TextField(
          controller: answerController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '$a + $b = ?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(answerController.text.trim());
              Navigator.pop(context, value == (a + b));
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    answerController.dispose();
    return solved ?? false;
  }

  Future<bool> _showMemoryChallenge() async {
    const phrase = 'WAKE';
    final controller = TextEditingController();
    final solved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Memory Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Remember this phrase for 2 seconds:'),
            const SizedBox(height: 8),
            const Text(
              phrase,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Type phrase'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim().toUpperCase() == phrase,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    controller.dispose();
    return solved ?? false;
  }

  Future<bool> _showQrPlaceholderChallenge() async {
    final controller = TextEditingController();
    final solved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('QR Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan mode placeholder: type SCAN-DONE to dismiss.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'SCAN-DONE'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim().toUpperCase() == 'SCAN-DONE',
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    controller.dispose();
    return solved ?? false;
  }

  Future<bool> _showStepsChallenge() async {
    var taps = 0;
    final solved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Steps Challenge'),
          content: Text('Tap the button 12 times to simulate a short walk.\nCount: $taps/12'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => taps++);
                if (taps >= 12) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Step +1'),
            ),
          ],
        ),
      ),
    );

    return solved ?? false;
  }

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
                      onPressed: () => _stopWithChallenge(alarmId),
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
