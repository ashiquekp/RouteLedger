import 'dart:async';
import 'dart:convert';

import 'package:fl_location/fl_location.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';

@pragma('vm:entry-point')
void startLocationServiceHandler() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Location>? _streamSubscription;
  Box? _routesBox;
  DateTime? _activeSessionStart;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 1. Initialize Hive for background isolate
    await Hive.initFlutter();
    _routesBox = await Hive.openBox('background_session_box');

    _activeSessionStart = DateTime.now();
    print('[Background] Isolate started. Session: $_activeSessionStart');

    // 2. Start Location Stream
    _streamSubscription = FlLocation.getLocationStream(
      accuracy: LocationAccuracy.navigation,
      distanceFilter: 0,
    ).listen((location) async {
      print('[Background] Raw location: ${location.latitude}, ${location.longitude} (acc: ${location.accuracy})');
      
      // Send location data back to main app natively (if main app is alive, it draws to map)
      final String locationJson = jsonEncode(location.toJson());
      FlutterForegroundTask.sendDataToMain(locationJson);

      // Only save relatively accurate points
      if (location.accuracy <= 50) {
        await _saveLocationToHive(location);
      }
    });

    FlutterForegroundTask.updateService(
      notificationTitle: 'RouteLedger Tracking',
      notificationText: 'Tracking route actively',
    );
  }

  Future<void> _saveLocationToHive(Location location) async {
    if (_routesBox == null || _activeSessionStart == null) return;
    
    final dynamic data = _routesBox!.get('points');
    List<dynamic> rawList = [];
    if (data is List) {
      rawList = List.from(data);
    }
    
    final pointMap = {
      'lat': location.latitude,
      'lng': location.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    rawList.add(pointMap);
    await _routesBox!.put('points', rawList);
    await _routesBox!.put('start_time', _activeSessionStart!.millisecondsSinceEpoch);
    
    print('[Background] Saved point #${rawList.length}');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // optional interval handling
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    await _routesBox?.close();
  }
}
