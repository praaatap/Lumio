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
import 'smart_alarm_service.dart';
import 'storage_service.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final Uuid _uuid = const Uuid();

  static bool get _supportsNativeAlarmOps => !kIsWeb;

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    if (_supportsNativeAlarmOps) {
      await Alarm.init();
    }

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
    if (kIsWeb) {
      return;
    }

    await Permission.notification.request();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static Future<void> saveAlarm(AlarmModel alarm) async {
    await StorageService.saveAlarm(alarm);
  }

  static Future<void> scheduleAlarm(
    AlarmModel alarm, {
    bool persist = true,
  }) async {
    await _cancelScheduledArtifacts(alarm.id);

    if (!_supportsNativeAlarmOps) {
      if (persist) {
        await saveAlarm(alarm.copyWith(isEnabled: true));
      }
      return;
    }

    final targetTime = alarm.nextDateTimeFrom(DateTime.now());
    final alarmId = alarmIntId(alarm.id);
    final selectedSound = SmartAlarmService.rotateSoundForDate(
      targetTime,
      alarm.sound,
    );

    final settings = AlarmSettings(
      id: alarmId,
      dateTime: targetTime,
      assetAudioPath: selectedSound == 'default' ? null : selectedSound,
      volumeSettings: VolumeSettings.fade(fadeDuration: Duration(seconds: 8)),
      notificationSettings: NotificationSettings(
        title: alarm.label.isEmpty ? 'FlowMind Alarm' : alarm.label,
        body: alarm.aiTag,
      ),
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      androidFullScreenIntent: true,
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
      matchDateTimeComponents: alarm.repeatDays.isNotEmpty
          ? DateTimeComponents.time
          : null,
    );

    final windDownMinutes = await SmartAlarmService.getWindDownMinutes();
    final windDownTime = targetTime.subtract(
      Duration(minutes: windDownMinutes),
    );
    if (windDownTime.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        _windDownNotificationId(alarm.id),
        'Wind-down reminder',
        'Alarm in $windDownMinutes min. ${SmartAlarmService.windDownChecklist().join(' • ')}',
        tz.TZDateTime.from(windDownTime, location),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'flowmind_winddown',
            'FlowMind Wind-down',
            channelDescription: 'Pre-alarm sleep prep reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    if (persist) {
      await saveAlarm(alarm.copyWith(isEnabled: true));
    }
  }

  static Future<void> cancelAlarm(String id) async {
    await _cancelScheduledArtifacts(id);
  }

  static Future<void> deleteAlarm(String id) async {
    await _cancelScheduledArtifacts(id);
    await StorageService.deleteAlarm(id);
  }

  static Future<void> restoreEnabledAlarms() async {
    final alarms = getAllAlarms().where((alarm) => alarm.isEnabled);
    for (final alarm in alarms) {
      await scheduleAlarm(alarm, persist: false);
    }
  }

  static Future<void> _cancelScheduledArtifacts(String id) async {
    if (!_supportsNativeAlarmOps) {
      return;
    }

    final alarmId = alarmIntId(id);
    await Alarm.stop(alarmId);
    await _notifications.cancel(alarmId);
    await _notifications.cancel(_windDownNotificationId(id));
  }

  static Future<void> toggleAlarm(String id, bool on) async {
    final alarm = StorageService.getAlarm(id);
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

  static Future<List<AiAlarmChoice>> getDailyAlarmChoices({
    required int dayOfWeek,
    required String routine,
  }) async {
    return AiService().getDailyAlarmChoices(
      dayOfWeek: dayOfWeek,
      routine: routine,
    );
  }

  static Future<List<WeeklyAlarmPlanItem>> generateWeeklyAlarmPlan({
    required String routine,
    required String meetings,
    required bool gymDays,
    required int commuteMinutes,
    required int sleepDebtMinutes,
  }) async {
    return AiService().generateWeeklyAlarmPlan(
      routine: routine,
      meetings: meetings,
      gymDays: gymDays,
      commuteMinutes: commuteMinutes,
      sleepDebtMinutes: sleepDebtMinutes,
    );
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
    final prefix = sanitized.length >= 8
        ? sanitized.substring(0, 8)
        : sanitized;
    return int.tryParse(prefix, radix: 16) ?? id.hashCode.abs();
  }

  static int alarmIntId(String id) => _idToInt(id);

  static int _windDownNotificationId(String id) => alarmIntId(id) + 900000;

  static AlarmModel? findByIntId(int alarmId) {
    for (final alarm in getAllAlarms()) {
      if (alarmIntId(alarm.id) == alarmId) {
        return alarm;
      }
    }
    return null;
  }

  static Future<bool> autoAdjustNextAlarmFromMood({
    required int energy,
    required int sleepQuality,
  }) async {
    final alarms = getAllAlarms().where((alarm) => alarm.isEnabled).toList();
    if (alarms.isEmpty) {
      return false;
    }

    alarms.sort(
      (a, b) => a
          .nextDateTimeFrom(DateTime.now())
          .compareTo(b.nextDateTimeFrom(DateTime.now())),
    );
    final target = alarms.first;

    var deltaMinutes = 0;
    if (sleepQuality <= 2 || energy <= 2) {
      deltaMinutes = 15;
    } else if (sleepQuality >= 4 && energy >= 4) {
      deltaMinutes = -10;
    }

    if (deltaMinutes == 0) {
      return false;
    }

    final current = (target.time.hour * 60) + target.time.minute;
    final shifted = (current + deltaMinutes).clamp(0, (24 * 60) - 1);
    final updated = target.copyWith(
      time: TimeOfDay(hour: shifted ~/ 60, minute: shifted % 60),
      aiTag: 'Auto-adjusted from mood + sleep check-in',
    );

    await scheduleAlarm(updated);
    return true;
  }
}
