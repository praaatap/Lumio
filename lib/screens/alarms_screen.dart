import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/alarm_card.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'YOUR ALARMS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 3,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddAlarmSheet(context),
            icon: const Icon(Icons.add, size: 30),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          ...appState.alarms.map(
            (alarm) => AlarmCard(
              alarm: alarm,
              onToggle: (enabled) {
                appState.toggleAlarm(alarm.id, enabled);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlarmSheet(context),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Add Alarm'),
      ),
    );
  }

  void _showAddAlarmSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddAlarmSheet(),
    );
  }
}

class _AddAlarmSheet extends StatefulWidget {
  const _AddAlarmSheet();

  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  final TextEditingController _labelController = TextEditingController();

  int _hour = 7;
  int _minute = 30;
  bool _isAm = true;
  bool _setAlarm = true;
  String _aiTag = 'Optimal sleep cycle';
  String _sound = 'default';
  final Set<int> _repeatDays = {2, 3, 4, 5, 6};

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 86,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D7DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTimePicker(context),
              const SizedBox(height: 18),
              TextField(
                controller: _labelController,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Alarm label...',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 20,
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Repeat',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final selected = _repeatDays.contains(weekday);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _repeatDays.remove(weekday);
                          } else {
                            _repeatDays.add(weekday);
                          }
                        });
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: selected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: const Color(0xFFD4D7DD)),
                        ),
                        child: Center(
                          child: Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  fontSize: 18,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Sound',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _sound == 'default' ? 'Default Ringtone' : _sound,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI SUGGEST',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _aiTag,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _getAiSuggestion,
                      style: IconButton.styleFrom(backgroundColor: Colors.black),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 260.ms),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Set Alarm',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _setAlarm,
                    onChanged: (value) => setState(() => _setAlarm = value),
                    activeTrackColor: const Color(0xFF22C55E),
                    activeColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF020617),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 62),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'Set Alarm',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pickerNumber(
          value: _hour,
          min: 1,
          max: 12,
          onChanged: (value) => setState(() => _hour = value),
        ),
        const SizedBox(width: 16),
        Text(
          ':',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 78,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        _pickerNumber(
          value: _minute,
          min: 0,
          max: 59,
          onChanged: (value) => setState(() => _minute = value),
        ),
        const SizedBox(width: 20),
        Column(
          children: [
            _periodButton(label: 'AM', active: _isAm, onTap: () => setState(() => _isAm = true)),
            const SizedBox(height: 8),
            _periodButton(label: 'PM', active: !_isAm, onTap: () => setState(() => _isAm = false)),
          ],
        ),
      ],
    );
  }

  Widget _pickerNumber({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: () {
            final next = value + 1 > max ? min : value + 1;
            onChanged(next);
          },
          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 66, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: () {
            final next = value - 1 < min ? max : value - 1;
            onChanged(next);
          },
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
        ),
      ],
    );
  }

  Widget _periodButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: active ? Colors.black : const Color(0xFFB0B0B0),
        ),
      ),
    );
  }

  Future<void> _getAiSuggestion() async {
    final appState = context.read<AppState>();
    final suggestion = await appState.getAISuggestion(
      _labelController.text.trim().isEmpty
          ? 'Morning work routine and commute'
          : _labelController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _aiTag = suggestion;
    });
  }

  Future<void> _saveAlarm() async {
    final appState = context.read<AppState>();
    final hour24 = _isAm ? (_hour % 12) : (_hour % 12) + 12;

    await appState.addAlarm(
      time: TimeOfDay(hour: hour24, minute: _minute),
      label: _labelController.text.trim().isEmpty
          ? 'Work Morning'
          : _labelController.text.trim(),
      repeatDays: _repeatDays.toList()..sort(),
      isEnabled: _setAlarm,
      aiTag: _aiTag,
      sound: _sound,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }
}
