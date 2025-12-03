# Firebase Setup Guide for Konnected Beauty

This guide will help you set up Firebase Cloud Messaging (FCM) for push notifications in your Flutter app.

## Prerequisites

- A Firebase account (create one at https://firebase.google.com/)
- Flutter SDK installed
- Android Studio / Xcode installed (for platform-specific setup)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard:
   - Enter project name: "Konnected Beauty" (or your preferred name)
   - Enable/disable Google Analytics (optional)
   - Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the Android icon (or "Add app")
2. Fill in the details:
   - **Android package name**: `com.konnectedbeauty.app` (must match your `applicationId` in `android/app/build.gradle`)
   - **App nickname**: Konnected Beauty Android (optional)
   - **Debug signing certificate SHA-1**: (optional, for testing)
3. Click "Register app"
4. Download `google-services.json`
5. Place the file in: `android/app/google-services.json`

### Important: Verify google-services.json location

The file should be at:
```
konnected_beauty/android/app/google-services.json
```

## Step 3: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon (or "Add app")
2. Fill in the details:
   - **iOS bundle ID**: Check your `ios/Runner.xcodeproj` or `ios/Runner/Info.plist` for `PRODUCT_BUNDLE_IDENTIFIER`
   - **App nickname**: Konnected Beauty iOS (optional)
   - **App Store ID**: (optional)
3. Click "Register app"
4. Download `GoogleService-Info.plist`
5. Place the file in: `ios/Runner/GoogleService-Info.plist`

### Important: Verify GoogleService-Info.plist location

The file should be at:
```
konnected_beauty/ios/Runner/GoogleService-Info.plist
```

## Step 4: Enable Cloud Messaging API

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click on the **Cloud Messaging** tab
3. If not already enabled, enable **Cloud Messaging API (Legacy)**
4. Note your **Server key** (you'll need this for backend integration)

## Step 5: Install Dependencies

Run the following command in your project root:

```bash
cd konnected_beauty
flutter pub get
```

## Step 6: iOS Additional Setup

### 6.1 Update Podfile ✅ (Already done)

The Podfile has been updated to include:
```ruby
platform :ios, '12.0'
```

### 6.2 Update AppDelegate.swift ✅ (Already done)

The `AppDelegate.swift` has been updated to:
- Import FirebaseCore and FirebaseMessaging
- Configure Firebase on app launch
- Register for remote notifications
- Handle APNS token registration

### 6.3 Install iOS Pods

```bash
cd ios
pod install
cd ..
```

**Important:** You must run `pod install` after adding Firebase dependencies.

### 6.4 Enable Push Notifications Capability in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode (NOT `.xcodeproj`)
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and enable:
   - ✅ Remote notifications

### 6.5 Configure APNs Authentication Key (Required for Production)

For production builds, you need to configure APNs:

1. In Firebase Console, go to **Project Settings** → **Cloud Messaging** tab
2. Under **Apple app configuration**, upload your APNs Authentication Key or APNs Certificates
3. You can get this from [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)

**For Development/Testing:**
- You can use APNs Key (recommended) or APNs Certificate
- APNs Key is easier to manage and doesn't expire

### 6.6 Update Info.plist ✅ (Already done)

The notification permissions are already added to `ios/Runner/Info.plist`.

## Step 7: Android Additional Setup

### 7.1 Verify build.gradle files

The following files have been updated:
- ✅ `android/build.gradle` - Added Google Services classpath
- ✅ `android/app/build.gradle` - Added Google Services plugin
- ✅ `android/app/src/main/AndroidManifest.xml` - Added notification permissions

### 7.2 Verify google-services.json

Make sure `google-services.json` is in `android/app/` directory.

## Step 8: Test Firebase Integration

### 8.1 Run the App

```bash
flutter run
```

### 8.2 Check Logs

Look for these log messages:
- ✅ `🔔 Notification permission status: AuthorizationStatus.authorized`
- ✅ `🔑 FCM Token: <your-token>`

### 8.3 Send a Test Notification

1. In Firebase Console, go to **Cloud Messaging**
2. Click **Send your first message**
3. Enter notification title and text
4. Click **Send test message**
5. Enter your FCM token (from app logs)
6. Click **Test**

## Step 9: Backend Integration

### 9.1 Get FCM Token

The app automatically retrieves the FCM token. You can access it via:

```dart
final notificationService = FirebaseNotificationService();
final token = notificationService.fcmToken;
```

### 9.2 Send Token to Your Backend

You need to send the FCM token to your backend API so it can send notifications to specific devices.

Example API call:
```dart
// In your auth service or profile service
Future<void> sendFCMTokenToBackend(String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/user/fcm-token'),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'fcmToken': token}),
  );
  // Handle response
}
```

### 9.3 Listen to Notification Stream

```dart
FirebaseNotificationService().notificationStream.listen((notification) {
  // Handle notification data
  print('Notification received: ${notification['title']}');
  // Navigate to specific screen based on notification data
});
```

## Step 10: Handle Notification Navigation

You can customize navigation based on notification data in `firebase_notification_service.dart`:

```dart
void _handleBackgroundMessage(RemoteMessage message) {
  // Example: Navigate based on notification type
  if (message.data['type'] == 'campaign') {
    // Navigate to campaign details
  } else if (message.data['type'] == 'order') {
    // Navigate to order details
  }
}
```

## Troubleshooting

### Android Issues

1. **Build Error: "google-services.json not found"**
   - Verify the file is at `android/app/google-services.json`
   - Clean and rebuild: `flutter clean && flutter pub get && flutter run`

2. **Notifications not showing**
   - Check AndroidManifest.xml has notification permissions
   - Verify notification channel is created (done automatically)

### iOS Issues

1. **Build Error: "GoogleService-Info.plist not found"**
   - Verify the file is at `ios/Runner/GoogleService-Info.plist`
   - Run `pod install` in `ios/` directory
   - Clean build folder: In Xcode, Product → Clean Build Folder (Shift+Cmd+K)

2. **Build Error: "No such module 'FirebaseCore'" or similar**
   - Run `cd ios && pod install && cd ..`
   - Make sure you're opening `Runner.xcworkspace` not `Runner.xcodeproj`
   - Clean and rebuild the project

3. **Notifications not working**
   - Check Push Notifications capability is enabled in Xcode
   - Verify Background Modes includes Remote notifications
   - Check device/simulator supports notifications (simulator has limitations)
   - Verify APNs is configured in Firebase Console (required for production)
   - Check that `AppDelegate.swift` has Firebase configuration code

4. **APNs Token Registration Failed**
   - Verify your Apple Developer account has Push Notifications enabled
   - Check that your provisioning profile includes Push Notifications capability
   - For development, make sure you're using a development provisioning profile
   - For production, upload APNs Authentication Key in Firebase Console

5. **Notifications work on device but not simulator**
   - iOS Simulator has limited notification support
   - Always test push notifications on a real iOS device
   - Simulator can receive notifications but may not display them properly

### General Issues

1. **FCM Token is null**
   - Check internet connection
   - Verify Firebase initialization completed
   - Check app logs for errors

2. **Notifications not received**
   - Verify FCM token is sent to backend
   - Check Firebase Console for delivery status
   - Ensure notification payload is correct

## Next Steps

1. ✅ Firebase is now integrated
2. 🔄 Send FCM token to your backend API
3. 🔄 Implement notification handling logic
4. 🔄 Test notifications from backend
5. 🔄 Add notification badges and sounds
6. 🔄 Implement notification actions (buttons)

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/migrate-v1)

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Review app logs for detailed error information
3. Verify all configuration files are in correct locations
4. Ensure all dependencies are installed correctly

