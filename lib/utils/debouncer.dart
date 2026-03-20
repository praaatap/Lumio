import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer utility to prevent rapid/duplicate function calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Call function after debounce delay
  /// Returns true if call was executed, false if debounced
  bool call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
    return false; // Call was registered for later, not executed now
  }

  /// Cancel any pending debounced call
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose the debouncer
  void dispose() {
    cancel();
  }
}
