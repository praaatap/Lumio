import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_model.dart';

class StorageService {
  static const String _settingsKey = 'flowmind_settings';
  static const String _alarmsKey = 'flowmind_alarms';
  
  static late final Box _alarmsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsKey); // Settings cached via SharedPreferences
    _alarmsBox = await Hive.openBox(_alarmsKey);
  }

  static Future<void> saveString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  static Future<String?> loadString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  static List<AlarmModel> getAllAlarms() {
    return _alarmsBox.values
        .whereType<Map>()
        .map((item) => AlarmModel.fromMap(item))
        .toList()
      ..sort((a, b) {
        final aMinutes = (a.time.hour * 60) + a.time.minute;
        final bMinutes = (b.time.hour * 60) + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  static Future<void> saveAlarm(AlarmModel alarm) async {
    await _alarmsBox.put(alarm.id, alarm.toMap());
  }

  static Future<void> deleteAlarm(String id) async {
    await _alarmsBox.delete(id);
  }

  static AlarmModel? getAlarm(String id) {
    final raw = _alarmsBox.get(id);
    if (raw is Map) {
      return AlarmModel.fromMap(raw);
    }
    return null;
  }
}
