import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../background/location_task_handler.dart';

class LocationService {
  static Future<void> start() async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'RouteLedger is tracking location',
      notificationText: 'Tap to return to app',
      callback: startCallback,
    );
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}
