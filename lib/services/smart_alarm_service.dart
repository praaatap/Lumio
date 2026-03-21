import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_model.dart';

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

class TeenSleepProfile {
  const TeenSleepProfile({
    required this.age,
    required this.targetSleepHours,
    required this.windDownMinutes,
  });

  final int age;
  final double targetSleepHours;
  final int windDownMinutes;

  Map<String, dynamic> toMap() => {
    'age': age,
    'targetSleepHours': targetSleepHours,
    'windDownMinutes': windDownMinutes,
  };

  factory TeenSleepProfile.fromMap(Map<String, dynamic> map) {
    return TeenSleepProfile(
      age: ((map['age'] as num?)?.toInt() ?? 16).clamp(13, 19),
      targetSleepHours: ((map['targetSleepHours'] as num?)?.toDouble() ?? 8.5)
          .clamp(7.0, 10.0),
      windDownMinutes: ((map['windDownMinutes'] as num?)?.toInt() ?? 30).clamp(
        15,
        60,
      ),
    );
  }
}

class SleepCoachSnapshot {
  const SleepCoachSnapshot({
    required this.profile,
    required this.recommendedSleepHours,
    required this.sleepDebtMinutes,
    required this.consistencyScore,
    required this.headline,
    required this.recommendation,
    this.nextWakeDateTime,
    this.suggestedBedtime,
  });

  final TeenSleepProfile profile;
  final double recommendedSleepHours;
  final int sleepDebtMinutes;
  final int consistencyScore;
  final String headline;
  final String recommendation;
  final DateTime? nextWakeDateTime;
  final TimeOfDay? suggestedBedtime;
}

class PremiumSleepSnapshot {
  const PremiumSleepSnapshot({
    required this.weekdayAverageWakeMinutes,
    required this.weekendAverageWakeMinutes,
    required this.weekendDriftMinutes,
    required this.recoveryIntensity,
    required this.recoveryHeadline,
    required this.recoveryActions,
  });

  final int? weekdayAverageWakeMinutes;
  final int? weekendAverageWakeMinutes;
  final int weekendDriftMinutes;
  final String recoveryIntensity;
  final String recoveryHeadline;
  final List<String> recoveryActions;
}

class SmartAlarmService {
  static const _challengeKey = 'smart.dismiss.challenge';
  static const _windDownMinutesKey = 'smart.winddown.minutes';
  static const _statsKey = 'smart.alarm.stats';
  static const _moodKey = 'smart.mood.latest';
  static const _teenSleepProfileKey = 'smart.sleep.profile';

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
    final clamped = minutes.clamp(15, 60);
    await prefs.setInt(_windDownMinutesKey, clamped);
    final profile = await getTeenSleepProfile();
    await prefs.setString(
      _teenSleepProfileKey,
      jsonEncode(profile.copyWith(windDownMinutes: clamped).toMap()),
    );
  }

  static TimeOfDay suggestBedtime({
    required TimeOfDay wakeTime,
    required double sleepHours,
  }) {
    final wakeMinutes = (wakeTime.hour * 60) + wakeTime.minute;
    final sleepMinutes = (sleepHours * 60).round();
    final bedtimeMinutes = (wakeMinutes - sleepMinutes) % (24 * 60);
    final positive = bedtimeMinutes < 0
        ? bedtimeMinutes + (24 * 60)
        : bedtimeMinutes;
    return TimeOfDay(hour: positive ~/ 60, minute: positive % 60);
  }

  static double recommendedSleepHoursForTeen(int age) {
    if (age <= 15) {
      return 9.0;
    }
    if (age <= 17) {
      return 8.75;
    }
    return 8.5;
  }

  static Future<TeenSleepProfile> getTeenSleepProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_teenSleepProfileKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return TeenSleepProfile.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // Fall back to defaults below.
      }
    }

    final windDown = prefs.getInt(_windDownMinutesKey) ?? 30;
    return TeenSleepProfile(
      age: 16,
      targetSleepHours: recommendedSleepHoursForTeen(16),
      windDownMinutes: windDown,
    );
  }

  static Future<void> saveTeenSleepProfile({
    int? age,
    double? targetSleepHours,
    int? windDownMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getTeenSleepProfile();
    final next = current.copyWith(
      age: age,
      targetSleepHours: targetSleepHours,
      windDownMinutes: windDownMinutes,
    );
    await prefs.setString(_teenSleepProfileKey, jsonEncode(next.toMap()));
    await prefs.setInt(_windDownMinutesKey, next.windDownMinutes);
  }

  static Future<SleepCoachSnapshot> buildSleepCoachSnapshot(
    List<AlarmModel> alarms,
  ) async {
    final profile = await getTeenSleepProfile();
    final mood = await getLatestMoodCheckIn();
    final enabled = alarms.where((alarm) => alarm.isEnabled).toList()
      ..sort(
        (a, b) => a
            .nextDateTimeFrom(DateTime.now())
            .compareTo(b.nextDateTimeFrom(DateTime.now())),
      );

    final nextWake = enabled.isEmpty
        ? null
        : enabled.first.nextDateTimeFrom(DateTime.now());
    final targetSleepHours = profile.targetSleepHours;
    final suggestedBedtime = nextWake == null
        ? null
        : suggestBedtime(
            wakeTime: TimeOfDay(hour: nextWake.hour, minute: nextWake.minute),
            sleepHours: targetSleepHours,
          );

    final recommended = recommendedSleepHoursForTeen(profile.age);
    final targetDebt = ((recommended - targetSleepHours) * 60).round();
    final moodDebt = mood == null
        ? 0
        : switch (mood.sleepQuality) {
            <= 2 => 45,
            3 => 20,
            4 => 10,
            _ => 0,
          };
    final sleepDebtMinutes = (targetDebt > 0 ? targetDebt : 0) + moodDebt;

    final alarmMinuteValues = enabled
        .map((alarm) => (alarm.time.hour * 60) + alarm.time.minute)
        .toList();
    final consistencyScore = _consistencyScore(alarmMinuteValues);

    final bedtimeText = suggestedBedtime == null
        ? 'Set a wake alarm to get a bedtime target.'
        : 'Aim to be in bed by ${formatTimeOfDay(suggestedBedtime)}.';
    final sleepDebtText = sleepDebtMinutes <= 0
        ? 'Your sleep target is on track.'
        : 'You are carrying about ${sleepDebtMinutes ~/ 60 > 0 ? '${sleepDebtMinutes ~/ 60}h ' : ''}${sleepDebtMinutes % 60}m of sleep debt.';
    final recommendation = mood == null
        ? '$bedtimeText Keep your wake time steady, even on weekends.'
        : mood.sleepQuality <= 2
        ? '$bedtimeText $sleepDebtText Cut screen time 30 minutes earlier tonight.'
        : '$bedtimeText $sleepDebtText Protect the same bedtime for the next 3 nights.';

    final headline = suggestedBedtime == null
        ? 'Teen sleep coach is ready once you enable an alarm.'
        : '${formatTimeOfDay(suggestedBedtime)} is your best bedtime for a ${targetSleepHours.toStringAsFixed(1)}h sleep goal.';

    return SleepCoachSnapshot(
      profile: profile,
      recommendedSleepHours: recommended,
      sleepDebtMinutes: sleepDebtMinutes,
      consistencyScore: consistencyScore,
      headline: headline,
      recommendation: recommendation,
      nextWakeDateTime: nextWake,
      suggestedBedtime: suggestedBedtime,
    );
  }

  static Future<PremiumSleepSnapshot> buildPremiumSleepSnapshot(
    List<AlarmModel> alarms,
  ) async {
    final coach = await buildSleepCoachSnapshot(alarms);
    final mood = await getLatestMoodCheckIn();
    final weekdayWake = _averageWakeMinutes(alarms, const [1, 2, 3, 4, 5]);
    final weekendWake = _averageWakeMinutes(alarms, const [6, 7]);
    final drift = weekdayWake == null || weekendWake == null
        ? 0
        : weekendWake - weekdayWake;

    final recoveryIntensity = switch (coach.sleepDebtMinutes) {
      >= 90 => 'High',
      >= 40 => 'Medium',
      _ => 'Light',
    };

    final driftText = drift <= 0
        ? 'Weekend wake time is stable.'
        : 'Weekend drift is $drift min later than weekdays.';
    final recoveryHeadline = mood != null && mood.sleepQuality <= 2
        ? 'Recovery mode recommended tomorrow. $driftText'
        : 'Sleep rhythm check: $driftText';

    final actions = <String>[
      if (coach.suggestedBedtime != null)
        'Start wind-down ${coach.profile.windDownMinutes} min before ${formatTimeOfDay(coach.suggestedBedtime!)}',
      if (drift > 75)
        'Pull weekend alarms earlier by 30-45 min to protect Monday energy',
      if (coach.sleepDebtMinutes >= 40)
        'Use a lighter first block tomorrow and avoid late caffeine',
      if (mood != null && mood.energy <= 2)
        'Keep the first task small and get sunlight within 30 minutes of waking',
      if (actionsWouldBeEmptyPlaceholder(
        coach: coach,
        drift: drift,
        mood: mood,
      ))
        'Your rhythm looks steady. Keep the same wake time for the next 3 days',
    ];

    return PremiumSleepSnapshot(
      weekdayAverageWakeMinutes: weekdayWake,
      weekendAverageWakeMinutes: weekendWake,
      weekendDriftMinutes: drift,
      recoveryIntensity: recoveryIntensity,
      recoveryHeadline: recoveryHeadline,
      recoveryActions: actions,
    );
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
      batteryIgnored = await Permission.ignoreBatteryOptimizations.status.then(
        (value) => value.isGranted,
      );
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

  static bool actionsWouldBeEmptyPlaceholder({
    required SleepCoachSnapshot coach,
    required int drift,
    required MoodCheckIn? mood,
  }) {
    return coach.suggestedBedtime == null &&
        drift <= 75 &&
        coach.sleepDebtMinutes < 40 &&
        (mood == null || mood.energy > 2);
  }

  static int? _averageWakeMinutes(
    List<AlarmModel> alarms,
    List<int> targetDays,
  ) {
    final matching = alarms.where((alarm) {
      if (!alarm.isEnabled) {
        return false;
      }
      if (alarm.repeatDays.isEmpty) {
        final nextDay = alarm.nextDateTimeFrom(DateTime.now()).weekday;
        return targetDays.contains(nextDay);
      }
      return alarm.repeatDays.any(targetDays.contains);
    }).toList();

    if (matching.isEmpty) {
      return null;
    }

    final total = matching.fold<int>(
      0,
      (sum, alarm) => sum + (alarm.time.hour * 60) + alarm.time.minute,
    );
    return (total / matching.length).round();
  }

  static int _consistencyScore(List<int> minuteValues) {
    if (minuteValues.length <= 1) {
      return 92;
    }

    final mean =
        minuteValues.reduce((a, b) => a + b) / minuteValues.length.toDouble();
    final variance =
        minuteValues.fold<double>(
          0,
          (sum, value) => sum + ((value - mean) * (value - mean)),
        ) /
        minuteValues.length.toDouble();
    final deviationMinutes = math.sqrt(variance);
    final score = 100 - (deviationMinutes * 0.9);
    return score.round().clamp(45, 100);
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }
}

extension on TeenSleepProfile {
  TeenSleepProfile copyWith({
    int? age,
    double? targetSleepHours,
    int? windDownMinutes,
  }) {
    return TeenSleepProfile(
      age: (age ?? this.age).clamp(13, 19),
      targetSleepHours: (targetSleepHours ?? this.targetSleepHours).clamp(
        7.0,
        10.0,
      ),
      windDownMinutes: (windDownMinutes ?? this.windDownMinutes).clamp(15, 60),
    );
  }
}
