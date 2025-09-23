import Flutter
import UIKit
import GoogleMaps
import PushNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4")

    // ✅ Pusher Beams Initialization (using PushNotifications.shared)
    let beams = PushNotifications.shared
    beams.start(instanceId: "1aeaf0d9-e6ba-4132-bee8-b152fe62ad54") // Replace with your instance ID

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ Device token registration for APNs
  override func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let beams = PushNotifications.shared
    beams.registerDeviceToken(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
