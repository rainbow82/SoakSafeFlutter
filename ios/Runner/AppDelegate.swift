import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppIconManager.shared.registerBackgroundRefresh()
    AppIconManager.shared.refreshIconFromIdleTime()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    AppIconManager.shared.onAppForeground()
    super.applicationDidBecomeActive(application)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    AppIconManager.shared.scheduleBackgroundRefresh()
    super.applicationDidEnterBackground(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
