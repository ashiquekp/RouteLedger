import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundInitializer {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'routeledger_tracking',
        channelName: 'RouteLedger Tracking',
        channelDescription: 'Location tracking is running',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // 5 seconds
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
    );
  }
}
