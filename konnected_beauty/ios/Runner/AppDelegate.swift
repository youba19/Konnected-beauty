import Flutter
import UIKit
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Note: Firebase is initialized in main.dart via FlutterFire
    // Do NOT call FirebaseApp.configure() here as it causes conflicts
    
    // Set up notification delegate
    // Note: Permission request is handled by Firebase Messaging in Dart
    // We just need to set the delegate and register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // Register for remote notifications (this requests APNS token)
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNS token registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Convert device token to string for logging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 APNS token received in AppDelegate: \(token.prefix(20))...")
    
    // Set APNS token in Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNS token set in Firebase Messaging")
    
    // Call super to ensure Flutter plugins also receive the token
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle APNS token registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    print("❌ Error details: \(error)")
    
    // Call super
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
