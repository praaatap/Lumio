import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../screens/alarm_ring_screen.dart';
import 'alarm_service.dart';
import 'smart_alarm_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AlarmRingFlow {
  static StreamSubscription<dynamic>? _ringSubscription;
  static bool _ringScreenVisible = false;
  static final Set<int> _knownRingingIds = <int>{};
  static final Map<int, Timer> _missedRecoveryTimers = <int, Timer>{};

  static void bindNativeAlarmEvents() {
    _ringSubscription ??= Alarm.ringing.listen((ringingSet) {
      final ids = ringingSet.alarms.map((alarm) => alarm.id).toSet();
      final newIds = ids.difference(_knownRingingIds);

      for (final id in newIds) {
        onAlarmRing(id);
      }

      _knownRingingIds
        ..clear()
        ..addAll(ids);

      if (ids.isEmpty) {
        _ringScreenVisible = false;
      }
    });
  }

  static Future<void> onAlarmRing(int alarmId) async {
    await WakelockPlus.enable();

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [500, 1000], repeat: 0);
      }
    } catch (_) {
      // Vibration capability differs by device.
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator != null && !_ringScreenVisible) {
      _ringScreenVisible = true;
      navigator.pushNamed(AlarmRingScreen.routeName, arguments: alarmId);
    }

    _missedRecoveryTimers[alarmId]?.cancel();
    _missedRecoveryTimers[alarmId] = Timer(const Duration(minutes: 2), () async {
      final alarm = AlarmService.findByIntId(alarmId);
      if (alarm == null) {
        return;
      }

      final stillRinging = await Alarm.isRinging(alarmId);
      if (!stillRinging) {
        return;
      }

      await SmartAlarmService.recordMissed();

      final backupTime = DateTime.now().add(const Duration(minutes: 3));
      final backup = alarm.copyWith(
        time: TimeOfDay(hour: backupTime.hour, minute: backupTime.minute),
        aiTag: 'Recovery backup alarm after missed ring',
        isEnabled: true,
      );
      await AlarmService.scheduleAlarm(backup);
    });
  }

  static Future<void> snoozeAlarm(int alarmId) async {
    final alarm = AlarmService.findByIntId(alarmId);
    if (alarm == null) {
      return;
    }

    await AlarmService.cancelAlarm(alarm.id);

    final newTime = DateTime.now().add(const Duration(minutes: 5));
    final updated = alarm.copyWith(
      time: TimeOfDay(hour: newTime.hour, minute: newTime.minute),
      isEnabled: true,
    );

    await AlarmService.scheduleAlarm(updated);
    await SmartAlarmService.recordSnoozed();
    await _stopEffects();

    appNavigatorKey.currentState?.pop();
    _ringScreenVisible = false;
  }

  static Future<void> stopAlarm(int alarmId) async {
    final alarm = AlarmService.findByIntId(alarmId);
    if (alarm == null) {
      return;
    }

    await AlarmService.cancelAlarm(alarm.id);

    if (alarm.repeatDays.isNotEmpty) {
      await AlarmService.scheduleAlarm(alarm);
    } else {
      await AlarmService.saveAlarm(alarm.copyWith(isEnabled: false));
    }

    await SmartAlarmService.recordDismissed();
    _missedRecoveryTimers[alarmId]?.cancel();
    _missedRecoveryTimers.remove(alarmId);

    await _stopEffects();
    appNavigatorKey.currentState?.pop();
    _ringScreenVisible = false;
  }

  static Future<void> _stopEffects() async {
    await Vibration.cancel();
    await WakelockPlus.disable();
  }
}
