import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("═══════════════════════════════════════════════════════")
    print("🚀 === APPDELEGATE DID FINISH LAUNCHING ===")
    print("═══════════════════════════════════════════════════════")
    
    // Configure Firebase (required for iOS push notifications)
    // This matches the working configuration from spotlightApp-prefinale
    FirebaseApp.configure()
    print("✅ Firebase configured in AppDelegate")
    
    // Set up notification delegate
    // Note: Permission request is handled by Firebase Messaging in Dart
    // We just need to set the delegate and register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      print("✅ UNUserNotificationCenter delegate set")
    }
    
    // Register for remote notifications (this requests APNS token)
    // This will trigger didRegisterForRemoteNotificationsWithDeviceToken when token is available
    print("📱 Registering for remote notifications...")
    application.registerForRemoteNotifications()
    print("✅ registerForRemoteNotifications() called")
    
    GeneratedPluginRegistrant.register(with: self)
    print("✅ GeneratedPluginRegistrant registered")
    print("═══════════════════════════════════════════════════════")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNS token registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Convert device token to string for logging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("═══════════════════════════════════════════════════════")
    print("📱 === APNS TOKEN RECEIVED IN APPDELEGATE ===")
    print("📱 APNS Token: \(token)")
    print("📱 Token Length: \(token.count) characters")
    print("═══════════════════════════════════════════════════════")
    
    // Set APNS token in Firebase Messaging (manually since swizzling is disabled)
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNS token set in Firebase Messaging")
    
    // Call super to ensure Flutter plugins also receive the token
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle remote notification received (when app is in foreground or background)
  override func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("═══════════════════════════════════════════════════════")
    print("📨 === REMOTE NOTIFICATION RECEIVED (AppDelegate) ===")
    print("📨 User Info: \(userInfo)")
    print("📨 Application State: \(application.applicationState.rawValue)")
    print("═══════════════════════════════════════════════════════")
    
    // Pass notification to Firebase Messaging
    Messaging.messaging().appDidReceiveMessage(userInfo)
    
    // Call super
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    
    completionHandler(.newData)
  }
  
  // Handle APNS token registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    print("❌ Error details: \(error)")
    
    // Call super
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  
  // Handle notification received in foreground (iOS 10+)
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("═══════════════════════════════════════════════════════")
    print("📨 === NOTIFICATION RECEIVED IN FOREGROUND (iOS) ===")
    print("📨 Title: \(notification.request.content.title)")
    print("📨 Body: \(notification.request.content.body)")
    print("📨 User Info: \(notification.request.content.userInfo)")
    print("═══════════════════════════════════════════════════════")
    
    // Show notification even when app is in foreground
    // This allows the notification to appear in the notification center
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound, .list])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
  
  // Handle notification tap (iOS 10+)
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    print("═══════════════════════════════════════════════════════")
    print("📨 === NOTIFICATION TAPPED (iOS) ===")
    print("📨 Title: \(response.notification.request.content.title)")
    print("📨 Body: \(response.notification.request.content.body)")
    print("📨 User Info: \(response.notification.request.content.userInfo)")
    print("═══════════════════════════════════════════════════════")
    
    // Call super to ensure Flutter plugins also receive the notification
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    completionHandler()
  }
}
