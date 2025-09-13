import Flutter
import UIKit
import GoogleMaps
import PusherPushNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAmN17lAC9v1BSdRB6Q_R75boSy_mXjDe4") // ✅ iOS key here

    // Pusher Beams Initialization - ADD THIS
    let beams = PusherPushNotifications()
    beams.start(instanceId: "1aeaf0d9-e6ba-4132-bee8-b152fe62ad54") // Replace with your actual instance ID

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Add this method for Pusher Beams device token registration
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let beams = PusherPushNotifications()
    beams.registerDeviceToken(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}