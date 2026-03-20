import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DismissChallengeType { none, math, memory, qr, steps }

enum DayTypeProfile { workday, gym, weekend, travel }

class AlarmReliabilityStatus {
  const AlarmReliabilityStatus({
    required this.notificationsGranted,
    required this.exactAlarmGranted,
    required this.batteryOptimizationIgnored,
  });

  final bool notificationsGranted;
  final bool exactAlarmGranted;
  final bool batteryOptimizationIgnored;
}

class AlarmStats {
  const AlarmStats({
    required this.dismissCount,
    required this.snoozeCount,
    required this.missedCount,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int dismissCount;
  final int snoozeCount;
  final int missedCount;
  final int currentStreak;
  final int bestStreak;
}

class MoodCheckIn {
  const MoodCheckIn({
    required this.energy,
    required this.mood,
    required this.sleepQuality,
    required this.at,
  });

  final int energy;
  final int mood;
  final int sleepQuality;
  final DateTime at;

  Map<String, dynamic> toMap() => {
        'energy': energy,
        'mood': mood,
        'sleepQuality': sleepQuality,
        'at': at.toIso8601String(),
      };

  factory MoodCheckIn.fromMap(Map<String, dynamic> map) {
    return MoodCheckIn(
      energy: (map['energy'] as num?)?.toInt() ?? 3,
      mood: (map['mood'] as num?)?.toInt() ?? 3,
      sleepQuality: (map['sleepQuality'] as num?)?.toInt() ?? 3,
      at: DateTime.tryParse(map['at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ParsedQuickAlarm {
  const ParsedQuickAlarm({
    required this.hour24,
    required this.minute,
    required this.label,
    required this.dayOffset,
  });

  final int hour24;
  final int minute;
  final String label;
  final int dayOffset;
}

class SmartAlarmService {
  static const _challengeKey = 'smart.dismiss.challenge';
  static const _windDownMinutesKey = 'smart.winddown.minutes';
  static const _statsKey = 'smart.alarm.stats';
  static const _moodKey = 'smart.mood.latest';

  static Future<DismissChallengeType> getDismissChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_challengeKey) ?? 'none';
    return DismissChallengeType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => DismissChallengeType.none,
    );
  }

  static Future<void> setDismissChallenge(DismissChallengeType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_challengeKey, type.name);
  }

  static Future<int> getWindDownMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_windDownMinutesKey) ?? 30;
  }

  static Future<void> setWindDownMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_windDownMinutesKey, minutes.clamp(15, 60));
  }

  static TimeOfDay suggestBedtime({
    required TimeOfDay wakeTime,
    required double sleepHours,
  }) {
    final wakeMinutes = (wakeTime.hour * 60) + wakeTime.minute;
    final sleepMinutes = (sleepHours * 60).round();
    final bedtimeMinutes = (wakeMinutes - sleepMinutes) % (24 * 60);
    final positive = bedtimeMinutes < 0 ? bedtimeMinutes + (24 * 60) : bedtimeMinutes;
    return TimeOfDay(hour: positive ~/ 60, minute: positive % 60);
  }

  static ({TimeOfDay time, List<int> repeatDays, String label, String aiTag})
      defaultsForProfile(DayTypeProfile profile) {
    switch (profile) {
      case DayTypeProfile.gym:
        return (
          time: const TimeOfDay(hour: 6, minute: 0),
          repeatDays: const [1, 2, 3, 4, 5],
          label: 'Gym Morning',
          aiTag: 'Training-first wake profile',
        );
      case DayTypeProfile.weekend:
        return (
          time: const TimeOfDay(hour: 8, minute: 15),
          repeatDays: const [6, 7],
          label: 'Weekend Reset',
          aiTag: 'Consistent but gentle weekend wake',
        );
      case DayTypeProfile.travel:
        return (
          time: const TimeOfDay(hour: 5, minute: 45),
          repeatDays: const [1, 2, 3, 4, 5, 6, 7],
          label: 'Travel Buffer',
          aiTag: 'Extra prep time for unpredictable mornings',
        );
      case DayTypeProfile.workday:
        return (
          time: const TimeOfDay(hour: 6, minute: 30),
          repeatDays: const [1, 2, 3, 4, 5],
          label: 'Work Morning',
          aiTag: 'Stable weekday rhythm',
        );
    }
  }

  static String rotateSoundForDate(DateTime date, String base) {
    if (base != 'rotate') {
      return base;
    }

    const palette = ['default', 'gentle', 'strong'];
    return palette[date.weekday % palette.length];
  }

  static Future<AlarmReliabilityStatus> getReliabilityStatus() async {
    final notification = await Permission.notification.status;
    final exactAlarm = await Permission.scheduleExactAlarm.status;

    var batteryIgnored = true;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      batteryIgnored = await Permission.ignoreBatteryOptimizations.status
          .then((value) => value.isGranted);
    }

    return AlarmReliabilityStatus(
      notificationsGranted: notification.isGranted,
      exactAlarmGranted: exactAlarm.isGranted,
      batteryOptimizationIgnored: batteryIgnored,
    );
  }

  static Future<void> recordDismissed() async {
    final stats = await getStats();
    final next = AlarmStats(
      dismissCount: stats.dismissCount + 1,
      snoozeCount: stats.snoozeCount,
      missedCount: stats.missedCount,
      currentStreak: stats.currentStreak + 1,
      bestStreak: (stats.currentStreak + 1) > stats.bestStreak
          ? stats.currentStreak + 1
          : stats.bestStreak,
    );
    await _saveStats(next);
  }

  static Future<void> recordSnoozed() async {
    final stats = await getStats();
    await _saveStats(
      AlarmStats(
        dismissCount: stats.dismissCount,
        snoozeCount: stats.snoozeCount + 1,
        missedCount: stats.missedCount,
        currentStreak: stats.currentStreak,
        bestStreak: stats.bestStreak,
      ),
    );
  }

  static Future<void> recordMissed() async {
    final stats = await getStats();
    await _saveStats(
      AlarmStats(
        dismissCount: stats.dismissCount,
        snoozeCount: stats.snoozeCount,
        missedCount: stats.missedCount + 1,
        currentStreak: 0,
        bestStreak: stats.bestStreak,
      ),
    );
  }

  static Future<AlarmStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null || raw.isEmpty) {
      return const AlarmStats(
        dismissCount: 0,
        snoozeCount: 0,
        missedCount: 0,
        currentStreak: 0,
        bestStreak: 0,
      );
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AlarmStats(
        dismissCount: (map['dismissCount'] as num?)?.toInt() ?? 0,
        snoozeCount: (map['snoozeCount'] as num?)?.toInt() ?? 0,
        missedCount: (map['missedCount'] as num?)?.toInt() ?? 0,
        currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
        bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const AlarmStats(
        dismissCount: 0,
        snoozeCount: 0,
        missedCount: 0,
        currentStreak: 0,
        bestStreak: 0,
      );
    }
  }

  static Future<void> _saveStats(AlarmStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _statsKey,
      jsonEncode({
        'dismissCount': stats.dismissCount,
        'snoozeCount': stats.snoozeCount,
        'missedCount': stats.missedCount,
        'currentStreak': stats.currentStreak,
        'bestStreak': stats.bestStreak,
      }),
    );
  }

  static Future<void> saveMoodCheckIn({
    required int energy,
    required int mood,
    required int sleepQuality,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final checkin = MoodCheckIn(
      energy: energy.clamp(1, 5),
      mood: mood.clamp(1, 5),
      sleepQuality: sleepQuality.clamp(1, 5),
      at: DateTime.now(),
    );
    await prefs.setString(_moodKey, jsonEncode(checkin.toMap()));
  }

  static Future<MoodCheckIn?> getLatestMoodCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_moodKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return MoodCheckIn.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  static ParsedQuickAlarm? parseQuickAdd(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) {
      return null;
    }

    final match = RegExp(r'(\d{1,2})[:.](\d{2})\s*(am|pm)?').firstMatch(lower);
    if (match == null) {
      return null;
    }

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!).clamp(0, 59);
    final period = match.group(3);
    if (period == 'pm' && hour < 12) {
      hour += 12;
    } else if (period == 'am' && hour == 12) {
      hour = 0;
    }
    hour = hour.clamp(0, 23);

    final dayOffset = lower.contains('tomorrow') ? 1 : 0;
    final label = lower.contains('gym')
        ? 'Gym Quick Add'
        : lower.contains('travel')
            ? 'Travel Quick Add'
            : 'Quick Add Alarm';

    return ParsedQuickAlarm(
      hour24: hour,
      minute: minute,
      label: label,
      dayOffset: dayOffset,
    );
  }

  static List<String> windDownChecklist() {
    return const [
      'Dim screen and reduce blue light',
      'Do 2 minutes of breathing',
      'No caffeine now',
      'Prep tomorrow task list',
    ];
  }
}
