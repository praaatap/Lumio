import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/alarm_providers.dart';
import '../services/ai_service.dart';
import '../utils/debouncer.dart';
import '../widgets/alarm_card.dart';

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsListProvider);

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
            onPressed: () => _showAddAlarmSheet(context, ref),
            icon: const Icon(Icons.add, size: 30),
          ),
        ],
      ),
      body: alarmsAsync.when(
        data: (alarms) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            ...alarms.map(
              (alarm) => AlarmCard(
                alarm: alarm,
                onToggle: (enabled) {
                  ref.read(alarmsMapProvider.notifier).toggleAlarm(alarm.id, enabled);
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlarmSheet(context, ref),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Add Alarm'),
      ),
    );
  }

  void _showAddAlarmSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAlarmSheet(ref: ref),
    );
  }
}

class _AddAlarmSheet extends ConsumerStatefulWidget {
  const _AddAlarmSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends ConsumerState<_AddAlarmSheet> {
  final TextEditingController _labelController = TextEditingController();
  late final Debouncer _aiDebouncer;

  int _hour = 7;
  int _minute = 30;
  bool _isAm = true;
  bool _setAlarm = true;
  String _aiTag = 'Optimal sleep cycle';
  String _sound = 'default';
  final Set<int> _repeatDays = {2, 3, 4, 5, 6};

  bool _loadingAI = false;
  String? _aiError;
  bool _loadingDailyChoices = false;
  String? _dailyChoicesError;
  List<AiAlarmChoice> _dailyChoices = const [];

  @override
  void initState() {
    super.initState();
    _aiDebouncer = Debouncer(delay: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _labelController.dispose();
    _aiDebouncer.dispose();
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
                            _aiError ?? _aiTag,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _aiError != null
                                  ? Colors.red
                                  : const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadingAI ? null : _getAiSuggestion,
                      style: IconButton.styleFrom(backgroundColor: Colors.black),
                      icon: _loadingAI
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 260.ms),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.model_training_outlined, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'GENKIT + GROQ DAILY CHOICES',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadingDailyChoices ? null : _getDailyChoices,
                          child: _loadingDailyChoices
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Generate'),
                        ),
                      ],
                    ),
                    if (_dailyChoicesError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _dailyChoicesError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                    if (_dailyChoices.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dailyChoices
                              .map(
                                (choice) => ActionChip(
                                  label: Text(
                                    '${_formatHour(choice.hour24)}:${choice.minute.toString().padLeft(2, '0')} ${choice.hour24 >= 12 ? 'PM' : 'AM'} · ${choice.label}',
                                  ),
                                  onPressed: () => _applyDailyChoice(choice),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
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

  int _targetDayForPrompt() {
    if (_repeatDays.isEmpty) {
      return DateTime.now().weekday;
    }
    final days = _repeatDays.toList()..sort();
    return days.first;
  }

  String _routinePrompt() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      return 'Work routine with healthy wake up and commute buffer';
    }
    return label;
  }

  int _formatHour(int hour24) {
    final normalized = hour24 % 12;
    return normalized == 0 ? 12 : normalized;
  }

  void _applyDailyChoice(AiAlarmChoice choice) {
    setState(() {
      _hour = _formatHour(choice.hour24);
      _minute = choice.minute;
      _isAm = choice.hour24 < 12;
      _labelController.text = choice.label;
      _aiTag = choice.aiTag;
      _aiError = null;
    });
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
    _aiDebouncer.call(() async {
      if (!mounted) return;

      setState(() {
        _loadingAI = true;
        _aiError = null;
      });

      try {
        final suggestion = await ref.read(aiSuggestionProvider(
          _labelController.text.trim().isEmpty
              ? 'Morning work routine and commute'
              : _labelController.text.trim(),
        ).future);

        if (!mounted) return;

        setState(() {
          _aiTag = suggestion;
          _loadingAI = false;
          _aiError = null;
        });
      } catch (e) {
        if (!mounted) return;

        debugPrint('Error getting AI suggestion: $e');
        setState(() {
          _loadingAI = false;
          _aiError = e is TimeoutException
              ? 'AI suggestion timed out'
              : 'Failed to get suggestion';
        });
      }
    });
  }

  Future<void> _getDailyChoices() async {
    if (!mounted) return;

    setState(() {
      _loadingDailyChoices = true;
      _dailyChoicesError = null;
    });

    try {
      final choices = await ref.read(
        dailyAlarmChoicesProvider(
          DailyAlarmChoicesRequest(
            dayOfWeek: _targetDayForPrompt(),
            routine: _routinePrompt(),
          ),
        ).future,
      );

      if (!mounted) return;

      setState(() {
        _loadingDailyChoices = false;
        _dailyChoices = choices;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingDailyChoices = false;
        _dailyChoicesError = e is TimeoutException
            ? 'Daily AI choices timed out'
            : 'Could not load daily choices';
      });
    }
  }

  Future<void> _saveAlarm() async {
    try {
      final hour24 = _isAm ? (_hour % 12) : (_hour % 12) + 12;

      await ref.read(alarmsMapProvider.notifier).addAlarm(
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
    } catch (e) {
      debugPrint('Error saving alarm: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save alarm: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
