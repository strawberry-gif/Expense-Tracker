import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final _controller = StreamController<bool>.broadcast();

  /// Stream of online(true)/offline(false).
  static Stream<bool> get onChange => _controller.stream;

  static bool _lastOnline = true;

  /// Start listening. Call once in main().
  static void start() {
    Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _lastOnline) {
        _lastOnline = online;
        _controller.add(online);
      }
    });

    // Prime the current state.
    Connectivity().checkConnectivity().then((results) {
      _lastOnline = !results.contains(ConnectivityResult.none);
      _controller.add(_lastOnline);
    });
  }

  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}