import 'dart:async';
import 'package:flutter/foundation.dart';

/// A debouncer utility to delay execution of a callback until after a specified duration
/// has elapsed since the last time it was invoked.
///
/// This is useful for search fields where you want to wait for the user to stop typing
/// before triggering an expensive operation like API calls or database queries.
///
/// Example:
/// ```dart
/// final debouncer = Debouncer(duration: Duration(milliseconds: 500));
///
/// TextField(
///   onChanged: (value) {
///     debouncer.run(() {
///       // This will only execute after user stops typing for 500ms
///       performSearch(value);
///     });
///   },
/// )
/// ```
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({
    this.duration = const Duration(milliseconds: 500),
  });

  /// Runs the given callback after the debounce duration has elapsed.
  /// If this method is called again before the duration elapses,
  /// the previous timer is cancelled and a new one is started.
  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }

  /// Cancels any pending callback.
  void cancel() {
    _timer?.cancel();
  }

  /// Disposes the debouncer and cancels any pending callback.
  /// Should be called when the debouncer is no longer needed.
  void dispose() {
    _timer?.cancel();
  }
}
