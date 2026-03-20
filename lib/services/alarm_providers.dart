import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alarm_model.dart';
import 'ai_service.dart';
import 'alarm_service.dart';

class DailyAlarmChoicesRequest {
  const DailyAlarmChoicesRequest({
    required this.dayOfWeek,
    required this.routine,
  });

  final int dayOfWeek;
  final String routine;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyAlarmChoicesRequest &&
        other.dayOfWeek == dayOfWeek &&
        other.routine == routine;
  }

  @override
  int get hashCode => Object.hash(dayOfWeek, routine);
}

/// Provider for the current tab index
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for alarms map state
class AlarmsNotifier extends StateNotifier<Future<Map<String, AlarmModel>>> {
  AlarmsNotifier() : super(_loadInitialAlarms());

  static Future<Map<String, AlarmModel>> _loadInitialAlarms() async {
    final alarms = AlarmService.getAllAlarms();
    final map = <String, AlarmModel>{};
    for (final alarm in alarms) {
      map[alarm.id] = alarm;
    }

    if (map.isEmpty) {
      await _createDefaultAlarms(map);
    }

    return map;
  }

  static Future<void> _createDefaultAlarms(Map<String, AlarmModel> map) async {
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
      map[alarm.id] = alarm;
      if (alarm.isEnabled) {
        await AlarmService.scheduleAlarm(alarm);
      }
    }
  }

  /// Save alarm and update local map
  Future<void> saveAlarm(AlarmModel alarm) async {
    try {
      await AlarmService.saveAlarm(alarm);
      final map = await state;
      map[alarm.id] = alarm;
      if (alarm.isEnabled) {
        await AlarmService.scheduleAlarm(alarm);
      }
      state = Future.value(Map.from(map));
    } catch (e) {
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

  /// Toggle alarm on/off
  Future<void> toggleAlarm(String id, bool on) async {
    final map = await state;
    final alarm = map[id];
    if (alarm == null) return;

    final updated = alarm.copyWith(isEnabled: on);
    await AlarmService.toggleAlarm(id, on);
    map[id] = updated;
    state = Future.value(Map.from(map));
  }

  /// Cancel alarm and remove it
  Future<void> cancelAlarm(String id) async {
    await AlarmService.cancelAlarm(id);
    final map = await state;
    map.remove(id);
    state = Future.value(Map.from(map));
  }

  /// Snooze alarm for 5 minutes
  Future<void> snoozeAlarm(String id) async {
    final map = await state;
    final alarm = map[id];
    if (alarm == null) return;

    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final updated = alarm.copyWith(
      time: TimeOfDay(hour: snoozeTime.hour, minute: snoozeTime.minute),
      isEnabled: true,
    );
    await saveAlarm(updated);
  }

  /// Stop alarm
  Future<void> stopAlarm(String id) async {
    final map = await state;
    final alarm = map[id];
    if (alarm == null) return;

    await AlarmService.cancelAlarm(id);

    if (alarm.repeatDays.isNotEmpty) {
      await AlarmService.scheduleAlarm(alarm);
    } else {
      final updated = alarm.copyWith(isEnabled: false);
      map[id] = updated;
      await AlarmService.saveAlarm(updated);
    }
    state = Future.value(Map.from(map));
  }
}

final alarmsMapProvider =
    StateNotifierProvider<AlarmsNotifier, Future<Map<String, AlarmModel>>>(
  (ref) => AlarmsNotifier(),
);

/// Provider for sorted alarms list (UI use)
final alarmsListProvider = FutureProvider<List<AlarmModel>>((ref) async {
  final map = await ref.watch(alarmsMapProvider);
  final sorted = map.values.toList();
  sorted.sort((a, b) {
    final aMinutes = (a.time.hour * 60) + a.time.minute;
    final bMinutes = (b.time.hour * 60) + b.time.minute;
    return aMinutes.compareTo(bMinutes);
  });
  return sorted;
});

/// Provider for vibration setting
final vibrationEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for AI suggestions setting
final aiSuggestionsEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for theme setting
final themeDarkProvider = StateProvider<bool>((ref) => false);

/// Provider for AI suggestion with timeout
final aiSuggestionProvider = FutureProvider.family<String, String>(
  (ref, routine) async {
    try {
      return await AlarmService.getAISuggestion(routine).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('AI suggestion timed out'),
      );
    } catch (e) {
      rethrow;
    }
  },
);

final dailyAlarmChoicesProvider =
    FutureProvider.family<List<AiAlarmChoice>, DailyAlarmChoicesRequest>(
  (ref, request) async {
    return AlarmService.getDailyAlarmChoices(
      dayOfWeek: request.dayOfWeek,
      routine: request.routine,
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException('Daily alarm choices timed out'),
    );
  },
);
