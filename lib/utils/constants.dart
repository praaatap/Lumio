import 'package:flutter/material.dart';

// Colors
class AppColors {
  static const Color primary = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF22C55E);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
}

// Durations
class AppDurations {
  static const Duration focusTimerDefault = Duration(minutes: 25);
  static const Duration snoozeTime = Duration(minutes: 5);
  static const Duration alarmFadeDuration = Duration(seconds: 8);
  static const Duration animationDuration = Duration(milliseconds: 280);
  static const Duration vibrationPattern1 = Duration(milliseconds: 500);
  static const Duration vibrationPattern2 = Duration(milliseconds: 1000);
}

// Animations
class AppAnimations {
  static const Duration splashDuration = Duration(milliseconds: 2600);
  static const Duration fadeInDuration = Duration(milliseconds: 280);
  static const Curve fadeCurve = Curves.easeOut;
}

// Alarm-specific
class AlarmDefaults {
  static const String soundDefault = 'default';
  static const String aiTagDefault = 'Optimal sleep cycle';
  static const String labelDefault = 'Work Morning';
  static const int defaultHour = 7;
  static const int defaultMinute = 30;
}

// UI dimensions
class AppDimensions {
  static const double paddingSmall = 8;
  static const double paddingMedium = 12;
  static const double paddingLarge = 16;
  static const double paddingXLarge = 22;
  static const double paddingXXLarge = 24;
  
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 28;
  
  static const double iconSizeMedium = 30;
}

// Text styles
class AppTextStyles {
  static const double letterSpacingTitle = 3;
  static const double letterSpacingLabel = 1;
}

// Repeat days presets
class RepeatDaysPresets {
  static const List<int> daily = [1, 2, 3, 4, 5, 6, 7];
  static const List<int> weekdays = [1, 2, 3, 4, 5];
  static const List<int> weekends = [6, 7];
}
