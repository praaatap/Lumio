import 'package:alarm/alarm.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/alarm_model.dart';
import 'ai_service.dart';
import 'storage_service.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final Uuid _uuid = const Uuid();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    await Alarm.init();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await AndroidAlarmManager.initialize();
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _notifications.initialize(settings);
    await requestPermissions();
  }

  static Future<void> requestPermissions() async {
    await Permission.notification.request();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static Future<void> saveAlarm(AlarmModel alarm) async {
    await StorageService.saveAlarm(alarm);
  }

  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    final targetTime = alarm.nextDateTimeFrom(DateTime.now());
    final alarmId = alarmIntId(alarm.id);

    final settings = AlarmSettings(
      id: alarmId,
      dateTime: targetTime,
      assetAudioPath: alarm.sound == 'default' ? 'assets/alarm.mp3' : alarm.sound,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      androidFullScreenIntent: true,
      notificationTitle: alarm.label.isEmpty ? 'FlowMind Alarm' : alarm.label,
      notificationBody: alarm.aiTag,
      enableNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: settings);

    final location = tz.local;
    final zoned = tz.TZDateTime.from(targetTime, location);

    await _notifications.zonedSchedule(
      alarmId,
      alarm.label.isEmpty ? 'FlowMind Alarm' : alarm.label,
      alarm.aiTag,
      zoned,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flowmind_alarms',
          'FlowMind Alarms',
          channelDescription: 'Daily and weekly smart alarm reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          alarm.repeatDays.isNotEmpty ? DateTimeComponents.time : null,
    );

    await saveAlarm(alarm.copyWith(isEnabled: true));
  }

  static Future<void> cancelAlarm(String id) async {
    final alarmId = alarmIntId(id);
    await Alarm.stop(alarmId);
    await _notifications.cancel(alarmId);
  }

  static Future<void> toggleAlarm(String id, bool on) async {
    final alarm = await StorageService.getAlarm(id);
    if (alarm == null) {
      return;
    }

    final updated = alarm.copyWith(isEnabled: on);
    await saveAlarm(updated);

    if (on) {
      await scheduleAlarm(updated);
    } else {
      await cancelAlarm(id);
    }
  }

  static Future<String> getAISuggestion(String routine) async {
    return AiService().getAISuggestion(routine);
  }

  static List<AlarmModel> getAllAlarms() {
    return StorageService.getAllAlarms();
  }

  static AlarmModel createAlarm({
    required TimeOfDay time,
    required String label,
    required List<int> repeatDays,
    required bool isEnabled,
    required String aiTag,
    String sound = 'default',
  }) {
    return AlarmModel(
      id: _uuid.v4(),
      time: time,
      label: label,
      repeatDays: repeatDays,
      isEnabled: isEnabled,
      aiTag: aiTag,
      sound: sound,
    );
  }

  static String formatTimeLabel(DateTime value) {
    return DateFormat('hh:mm a').format(value);
  }

  static int _idToInt(String id) {
    final sanitized = id.replaceAll('-', '');
    final prefix = sanitized.length >= 8 ? sanitized.substring(0, 8) : sanitized;
    return int.tryParse(prefix, radix: 16) ?? id.hashCode.abs();
  }

  static int alarmIntId(String id) => _idToInt(id);

  static AlarmModel? findByIntId(int alarmId) {
    for (final alarm in getAllAlarms()) {
      if (alarmIntId(alarm.id) == alarmId) {
        return alarm;
      }
    }
    return null;
  }
}
