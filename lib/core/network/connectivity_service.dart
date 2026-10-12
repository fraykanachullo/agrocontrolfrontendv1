import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  ConnectivityStatus get currentStatus => _currentStatus;

  void init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected =
          results.any((r) => r != ConnectivityResult.none);
      final newStatus =
          isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline;

      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _controller.add(newStatus);
      }
    });
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
