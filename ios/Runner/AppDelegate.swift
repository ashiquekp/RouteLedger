import Flutter
import UIKit
import flutter_foreground_task

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Required for background isolate in iOS for Flutter Foreground Task v8
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(registerPlugins)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// Global function to register plugins on the isolate 
func registerPlugins(registry: FlutterPluginRegistry) {
  GeneratedPluginRegistrant.register(with: registry)
}
