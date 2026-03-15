import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlarmModel {
  AlarmModel({
    required this.id,
    required this.time,
    required this.label,
    required this.repeatDays,
    required this.isEnabled,
    required this.aiTag,
    required this.sound,
  });

  final String id;
  final TimeOfDay time;
  final String label;
  final List<int> repeatDays;
  final bool isEnabled;
  final String aiTag;
  final String sound;

  String get timeLabel {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm').format(date);
  }

  String get periodLabel {
    return time.hour >= 12 ? 'PM' : 'AM';
  }

  String get repeatLabel {
    if (repeatDays.length == 7) {
      return 'Daily';
    }
    if (repeatDays.join(',') == '1,2,3,4,5') {
      return 'Weekdays';
    }
    if (repeatDays.join(',') == '6,7') {
      return 'Weekends';
    }
    return 'Custom';
  }

  DateTime nextDateTimeFrom(DateTime from) {
    var candidate = DateTime(
      from.year,
      from.month,
      from.day,
      time.hour,
      time.minute,
    );

    if (repeatDays.isEmpty) {
      if (candidate.isBefore(from)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    while (true) {
      final weekday = candidate.weekday;
      final validDay = repeatDays.contains(weekday);
      if (validDay && candidate.isAfter(from)) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'label': label,
      'repeatDays': repeatDays,
      'isEnabled': isEnabled,
      'aiTag': aiTag,
      'sound': sound,
    };
  }

  factory AlarmModel.fromMap(Map<dynamic, dynamic> map) {
    final rawDays = (map['repeatDays'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item is int ? item : int.parse(item.toString()))
        .toList();

    return AlarmModel(
      id: map['id'] as String,
      time: TimeOfDay(
        hour: map['hour'] as int,
        minute: map['minute'] as int,
      ),
      label: (map['label'] as String?) ?? '',
      repeatDays: rawDays,
      isEnabled: (map['isEnabled'] as bool?) ?? true,
      aiTag: (map['aiTag'] as String?) ?? 'Optimal sleep cycle',
      sound: (map['sound'] as String?) ?? 'default',
    );
  }

  AlarmModel copyWith({
    String? id,
    TimeOfDay? time,
    String? label,
    List<int>? repeatDays,
    bool? isEnabled,
    String? aiTag,
    String? sound,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      aiTag: aiTag ?? this.aiTag,
      sound: sound ?? this.sound,
    );
  }
}
