import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  Timer? _timer;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    bool previous = _isOnline;
    try {
      if (kIsWeb) {
        _isOnline = true; // Bypassing dart:io check on web
      } else {
        final result = await InternetAddress.lookup('google.com');
        _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (_) {
      _isOnline = false;
    }

    if (previous != _isOnline) {
      notifyListeners();
    }
  }
}
