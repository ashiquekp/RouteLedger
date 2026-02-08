import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';
import 'location_permission.dart';

final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingController, bool>(
  (ref) => LocationTrackingController(),
);

class LocationTrackingController extends StateNotifier<bool> {
  LocationTrackingController() : super(false);

  Future<void> startTracking() async {
    final hasPermission =
        await LocationPermissionHelper.ensurePermission();

    if (!hasPermission) return;

    await LocationService.start();
    state = true;
  }

  Future<void> stopTracking() async {
    await LocationService.stop();
    state = false;
  }
}
