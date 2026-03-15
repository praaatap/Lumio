import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/alarm_model.dart';
import 'alarm_service.dart';

class AppState extends ChangeNotifier {
  int _currentTabIndex = 0;
  final List<AlarmModel> _alarms = [];

  bool _vibrationEnabled = true;
  bool _aiSuggestionsEnabled = true;
  bool _themeDark = false;

  int get currentTabIndex => _currentTabIndex;
  List<AlarmModel> get alarms => List.unmodifiable(_alarms);
  bool get vibrationEnabled => _vibrationEnabled;
  bool get aiSuggestionsEnabled => _aiSuggestionsEnabled;
  bool get themeDark => _themeDark;

  Future<void> loadAlarms() async {
    _alarms
      ..clear()
      ..addAll(AlarmService.getAllAlarms());

    if (_alarms.isEmpty) {
      final defaults = [
        AlarmService.createAlarm(
          time: const TimeOfDay(hour: 6, minute: 30),
          label: 'Work Morning',
          repeatDays: const [1, 2, 3, 4, 5],
          isEnabled: true,
          aiTag: 'Optimal sleep cycle',
        ),
        AlarmService.createAlarm(
          time: const TimeOfDay(hour: 7, minute: 15),
          label: 'Gentle Wake',
          repeatDays: const [1, 2, 3, 4, 5, 6, 7],
          isEnabled: true,
          aiTag: 'Gentle wake AI',
        ),
      ];

      for (final alarm in defaults) {
        await AlarmService.saveAlarm(alarm);
        if (alarm.isEnabled) {
          await AlarmService.scheduleAlarm(alarm);
        }
      }

      _alarms
        ..clear()
        ..addAll(AlarmService.getAllAlarms());
    }

    notifyListeners();
  }

  void setCurrentTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    await AlarmService.saveAlarm(alarm);
    if (alarm.isEnabled) {
      await AlarmService.scheduleAlarm(alarm);
    }
    await loadAlarms();
  }

  Future<void> addAlarm({
    required TimeOfDay time,
    required String label,
    required List<int> repeatDays,
    required bool isEnabled,
    required String aiTag,
    String sound = 'default',
  }) async {
    final alarm = AlarmService.createAlarm(
      time: time,
      label: label,
      repeatDays: repeatDays,
      isEnabled: isEnabled,
      aiTag: aiTag,
      sound: sound,
    );
    await saveAlarm(alarm);
  }

  Future<void> toggleAlarm(String id, bool on) async {
    await AlarmService.toggleAlarm(id, on);
    await loadAlarms();
  }

  Future<void> cancelAlarm(String id) async {
    await AlarmService.cancelAlarm(id);
    _alarms.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> snoozeAlarm(String id) async {
    final alarm = _alarms.firstWhere((item) => item.id == id);
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));

    final updated = alarm.copyWith(
      time: TimeOfDay(hour: snoozeTime.hour, minute: snoozeTime.minute),
      isEnabled: true,
    );

    await saveAlarm(updated);
  }

  Future<void> stopAlarm(String id) async {
    final alarm = _alarms.firstWhere((item) => item.id == id);
    await AlarmService.cancelAlarm(id);

    if (alarm.repeatDays.isNotEmpty) {
      await AlarmService.scheduleAlarm(alarm);
    } else {
      await AlarmService.saveAlarm(alarm.copyWith(isEnabled: false));
    }

    await loadAlarms();
  }

  Future<String> getAISuggestion(String routine) async {
    return AlarmService.getAISuggestion(routine);
  }

  List<AlarmModel> getAllAlarms() {
    return AlarmService.getAllAlarms();
  }

  void setVibration(bool enabled) {
    _vibrationEnabled = enabled;
    notifyListeners();
  }

  void setAiSuggestions(bool enabled) {
    _aiSuggestionsEnabled = enabled;
    notifyListeners();
  }

  void setDarkTheme(bool enabled) {
    _themeDark = enabled;
    notifyListeners();
  }
}
