import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../screens/alarm_ring_screen.dart';
import 'alarm_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AlarmRingFlow {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> onAlarmRing(int alarmId) async {
    await WakelockPlus.enable();

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('alarm.mp3'));
    } catch (_) {
      // Audio asset is optional during development.
    }

    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [500, 1000], repeat: 0);
      }
    } catch (_) {
      // Vibration capability differs by device.
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamed(AlarmRingScreen.routeName, arguments: alarmId);
    }
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
    await _stopEffects();

    appNavigatorKey.currentState?.pop();
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

    await _stopEffects();
    appNavigatorKey.currentState?.pop();
  }

  static Future<void> _stopEffects() async {
    await _player.stop();
    await Vibration.cancel();
    await WakelockPlus.disable();
  }
}
