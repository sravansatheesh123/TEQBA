import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;
  final Rx<List<ConnectivityResult>> connectivityResults = Rx<List<ConnectivityResult>>([ConnectivityResult.wifi]);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Callback hook for auto-sync on reconnect
  Function()? onConnectionRestored;

  Future<ConnectivityService> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (_) {
      isOnline.value = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !isOnline.value;
      _updateConnectionStatus(results);
      if (wasOffline && isOnline.value) {
        onConnectionRestored?.call();
      }
    });

    return this;
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    connectivityResults.value = results;
    final connected = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    isOnline.value = connected;
  }

  bool get currentStatus => isOnline.value;

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
