import 'package:flutter/material.dart';

import '../models/alarm_model.dart';
import 'alarm_service.dart';

class AppState extends ChangeNotifier {
  int _currentTabIndex = 0;
  final Map<String, AlarmModel> _alarmsMap = {};

  bool _vibrationEnabled = true;
  bool _aiSuggestionsEnabled = true;
  bool _themeDark = false;

  int get currentTabIndex => _currentTabIndex;

  /// Returns alarms sorted by time for UI display
  List<AlarmModel> get alarms {
    final sorted = _alarmsMap.values.toList();
    sorted.sort((a, b) {
      final aMinutes = (a.time.hour * 60) + a.time.minute;
      final bMinutes = (b.time.hour * 60) + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return sorted;
  }

  bool get vibrationEnabled => _vibrationEnabled;
  bool get aiSuggestionsEnabled => _aiSuggestionsEnabled;
  bool get themeDark => _themeDark;

  /// Load alarms from storage (initial load only)
  Future<void> loadAlarms() async {
    try {
      final alarms = AlarmService.getAllAlarms();
      _alarmsMap.clear();
      for (final alarm in alarms) {
        _alarmsMap[alarm.id] = alarm;
      }

      if (_alarmsMap.isEmpty) {
        await _createDefaultAlarms();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading alarms: $e');
      rethrow;
    }
  }

  /// Create and schedule default alarms
  Future<void> _createDefaultAlarms() async {
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
      _alarmsMap[alarm.id] = alarm;
      if (alarm.isEnabled) {
        await AlarmService.scheduleAlarm(alarm);
      }
    }
  }

  void setCurrentTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Save alarm and update local map without full reload
  Future<void> saveAlarm(AlarmModel alarm) async {
    try {
      await AlarmService.saveAlarm(alarm);
      _alarmsMap[alarm.id] = alarm;
      if (alarm.isEnabled) {
        await AlarmService.scheduleAlarm(alarm);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving alarm: $e');
      rethrow;
    }
  }

  /// Add a new alarm
  Future<void> addAlarm({
    required TimeOfDay time,
    required String label,
    required List<int> repeatDays,
    required bool isEnabled,
    required String aiTag,
    String sound = 'default',
  }) async {
    try {
      final alarm = AlarmService.createAlarm(
        time: time,
        label: label,
        repeatDays: repeatDays,
        isEnabled: isEnabled,
        aiTag: aiTag,
        sound: sound,
      );
      await saveAlarm(alarm);
    } catch (e) {
      debugPrint('Error adding alarm: $e');
      rethrow;
    }
  }

  /// Toggle alarm on/off (targeted update, no full reload)
  Future<void> toggleAlarm(String id, bool on) async {
    try {
      final alarm = _alarmsMap[id];
      if (alarm == null) {
        debugPrint('Cannot toggle: alarm $id not found');
        return;
      }

      final updated = alarm.copyWith(isEnabled: on);
      await AlarmService.toggleAlarm(id, on);
      _alarmsMap[id] = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling alarm: $e');
      rethrow;
    }
  }

  /// Cancel alarm and remove it
  Future<void> cancelAlarm(String id) async {
    try {
      await AlarmService.deleteAlarm(id);
      _alarmsMap.remove(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error canceling alarm: $e');
      rethrow;
    }
  }

  /// Snooze alarm for 5 minutes (targeted update)
  Future<void> snoozeAlarm(String id) async {
    try {
      final alarm = _alarmsMap[id];
      if (alarm == null) {
        debugPrint('Cannot snooze: alarm $id not found');
        return;
      }

      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final updated = alarm.copyWith(
        time: TimeOfDay(hour: snoozeTime.hour, minute: snoozeTime.minute),
        isEnabled: true,
      );
      await saveAlarm(updated);
    } catch (e) {
      debugPrint('Error snoozing alarm: $e');
      rethrow;
    }
  }

  /// Stop alarm (reschedule if recurring, disable if one-time)
  Future<void> stopAlarm(String id) async {
    try {
      final alarm = _alarmsMap[id];
      if (alarm == null) {
        debugPrint('Cannot stop: alarm $id not found');
        return;
      }

      await AlarmService.cancelAlarm(id);

      if (alarm.repeatDays.isNotEmpty) {
        await AlarmService.scheduleAlarm(alarm);
      } else {
        final updated = alarm.copyWith(isEnabled: false);
        _alarmsMap[id] = updated;
        await AlarmService.saveAlarm(updated);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
      rethrow;
    }
  }

  Future<String> getAISuggestion(String routine) async {
    try {
      return await AlarmService.getAISuggestion(routine);
    } catch (e) {
      debugPrint('Error getting AI suggestion: $e');
      rethrow;
    }
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
