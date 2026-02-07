import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  bool _isChecking = false;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _checkConnectivity() async {
    _isChecking = true;
    notifyListeners();

    try {
      final result = await Connectivity().checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
    } catch (e) {
      _isConnected = false;
      if (kDebugMode) debugPrint('Connectivity check error: $e');
    }

    _isChecking = false;
    notifyListeners();
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    notifyListeners();
  }

  Future<bool> waitForConnection(
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (_isConnected) return true;

    final Stopwatch stopwatch = Stopwatch()..start();

    while (!_isConnected && stopwatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return _isConnected;
  }
}
