import 'dart:async';
import 'package:flutter/foundation.dart';

class CountdownController extends ChangeNotifier {
  bool _isActive = false;
  int _remaining = 0;
  Timer? _timer;

  bool get isActive => _isActive;
  int get remaining => _remaining;

  void start({required int durationSeconds, required VoidCallback onFinished}) {
    cancel();

    if (durationSeconds <= 0) {
      // Finish immediately; don’t enter an “active” state.
      scheduleMicrotask(onFinished);
      return;
    }

    _isActive = true;
    _remaining = durationSeconds;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _remaining - 1;

      if (next <= 0) {
        // Ensure UI ends in a clean state.
        cancel();
        scheduleMicrotask(onFinished);
      } else {
        _remaining = next;
        notifyListeners();
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;

    final wasActive = _isActive;
    _isActive = false;
    _remaining = 0;

    if (wasActive) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
