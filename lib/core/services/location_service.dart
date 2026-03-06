import 'dart:convert';
import 'dart:io';

import 'package:fl_location/fl_location.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../background/location_task_handler.dart';

typedef LocationChanged = void Function(Location location);

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  // ------------- Service API -------------
  Future<void> _requestPlatformPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Exact alarm permission
      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    if (!await FlLocation.isLocationServicesEnabled) {
      throw Exception('Location services is disabled.');
    }

    LocationPermission permission = await FlLocation.checkLocationPermission();
    if (permission == LocationPermission.denied) {
      permission = await FlLocation.requestLocationPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission has been ${permission.name}.');
    }

    if (Platform.isAndroid && permission == LocationPermission.whileInUse) {
      // Android: ACCESS_BACKGROUND_LOCATION
      permission = await FlLocation.requestLocationPermission();

      if (permission != LocationPermission.always) {
        throw Exception(
            'To start location service in the background cleanly, you should generally allow all the time, but we will proceed with what is granted.');
      }
    }
  }

  void init() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'route_tracking_service_iv',
        channelName: 'Route Tracking Service',
        channelDescription: 'Continuous location tracking',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> start() async {
    await _requestPlatformPermissions();
    await _requestLocationPermission();

    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
      serviceId: 201,
      notificationTitle: 'RouteLedger Tracking',
      notificationText: 'Tracking route actively',
      callback: startLocationServiceHandler,
    );

    if (result is ServiceRequestFailure) {
      throw result.error;
    }
  }

  Future<void> stop() async {
    final ServiceRequestResult result =
        await FlutterForegroundTask.stopService();

    if (result is ServiceRequestFailure) {
      throw result.error;
    }
  }

  Future<bool> get isRunningService => FlutterForegroundTask.isRunningService;

  // ------------- Service callback -------------
  final List<LocationChanged> _callbacks = [];

  void _onReceiveTaskData(Object data) {
    if (data is! String) {
      return;
    }
    
    // Attempt parsing as JSON
    try {
      final Map<String, dynamic> locationJson = jsonDecode(data);
      if(locationJson.containsKey('latitude')) {
        final Location location = Location.fromJson(locationJson);
        for (final LocationChanged callback in _callbacks.toList()) {
          callback(location);
        }
      }
    } catch(e) {
      // Might receive "STOP_TRACKING" or something custom, ignore if not JSON
    }
  }

  void addLocationChangedCallback(LocationChanged callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
  }

  void removeLocationChangedCallback(LocationChanged callback) {
    _callbacks.remove(callback);
  }
}
