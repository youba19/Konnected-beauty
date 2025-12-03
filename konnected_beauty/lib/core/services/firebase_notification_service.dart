import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;

/// Service for handling Firebase Cloud Messaging (FCM) notifications
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controller for notification data
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging and request permissions
  Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print(
          '🔔 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.notDetermined) {
        print('⏳ Notification permission not determined yet');
        print('ℹ️ User will be prompted on next app launch');
      } else {
        print('❌ User denied notification permission');
        print(
            'ℹ️ Please enable notifications in Settings → Konected → Notifications');
      }

      // Initialize local notifications for Android
      await _initializeLocalNotifications();

      // Configure message handlers (do this before getting token)
      _configureMessageHandlers();

      // Get FCM token (with retry for iOS APNS)
      // Only try if permission is granted or provisional
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Start token retrieval in background (non-blocking)
        // On iOS, wait longer for APNS token to be registered by the system
        final initialDelay = defaultTargetPlatform == TargetPlatform.iOS
            ? Duration(seconds: 5)
            : Duration(seconds: 2);

        print(
            '⏳ Waiting ${initialDelay.inSeconds} seconds before attempting to get FCM token...');
        Future.delayed(initialDelay, () {
          _getFCMTokenWithRetry().catchError((error) {
            print('❌ Failed to get FCM token: $error');
            // Continue trying in background
            _continueTokenRetrievalInBackground();
          });
        });
      } else {
        print('⚠️ Skipping FCM token retrieval - permission not granted');
        print('ℹ️ Token will be retrieved once user grants permission');
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // TODO: Send new token to your backend
      });
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    if (response.payload != null) {
      // Parse payload and navigate if needed
      // You can emit events here or navigate to specific screens
    }
  }

  /// Get FCM token with retry for iOS APNS
  Future<void> _getFCMTokenWithRetry({int maxRetries = 5}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // On iOS, wait for APNS token first
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          print(
              '📱 Attempting to get APNS token (attempt $attempt/$maxRetries)...');
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            final previewLength = apnsToken.length > 20 ? 20 : apnsToken.length;
            print(
                '✅ APNS Token received: ${apnsToken.substring(0, previewLength)}...');
          } else {
            print('⏳ APNS Token not available yet');
            if (attempt < maxRetries) {
              // Wait before retrying (longer delays for later attempts)
              final delay = attempt * 3;
              print('⏳ Waiting $delay seconds before retry...');
              await Future.delayed(Duration(seconds: delay));
              continue;
            } else {
              print('⚠️ APNS Token not available after $maxRetries attempts');
              print('ℹ️ Will continue trying in background...');
              // Start background retry
              _continueTokenRetrievalInBackground();
              return;
            }
          }
        }

        // Get FCM token
        print('🔑 Attempting to get FCM token...');
        _fcmToken = await _firebaseMessaging.getToken();

        if (_fcmToken == null) {
          throw Exception('FCM token is null');
        }

        // Print token prominently for easy copying
        print('');
        print('═══════════════════════════════════════════════════════');
        print('✅ FCM TOKEN SUCCESSFULLY RETRIEVED!');
        print('═══════════════════════════════════════════════════════');
        print('🔑 Copy this token to test notifications:');
        print('');
        print(_fcmToken);
        print('');
        print('═══════════════════════════════════════════════════════');
        print('📋 Use this token in Firebase Console → Cloud Messaging');
        print('   → Send test message → Enter FCM registration token');
        print('═══════════════════════════════════════════════════════');
        print('');

        // TODO: Send token to your backend API
        // Example:
        // await sendTokenToBackend(_fcmToken);
        return; // Success, exit retry loop
      } catch (e) {
        print('❌ Error getting FCM token (attempt $attempt/$maxRetries): $e');
        if (e.toString().contains('apns-token-not-set') ||
            e.toString().contains('permission') ||
            e.toString().contains('not authorized')) {
          if (attempt < maxRetries) {
            print('⏳ Retrying after delay...');
            await Future.delayed(Duration(seconds: attempt * 3));
            continue;
          } else {
            print('⚠️ Could not get FCM token after $maxRetries attempts');
            print('ℹ️ Will continue trying in background...');
            print('ℹ️ Common causes:');
            print('   1. APNS token takes time to be registered by iOS');
            print('   2. App needs to be in foreground for token registration');
            print('   3. Firebase not properly configured');
            print('ℹ️ Please check:');
            print(
                '   - Settings → Konected → Notifications (should be enabled)');
            print('   - GoogleService-Info.plist is in ios/Runner/');
            print('   - Xcode capabilities: Push Notifications enabled');
            // Start background retry
            _continueTokenRetrievalInBackground();
            return;
          }
        } else {
          // Different error, don't retry
          print('❌ Fatal error getting FCM token: $e');
          return;
        }
      }
    }
  }

  /// Get FCM token (legacy method, kept for compatibility)
  Future<void> _getFCMToken() async {
    await _getFCMTokenWithRetry();
  }

  /// Continue trying to get FCM token in background
  /// This is useful when APNS token takes longer to be available
  void _continueTokenRetrievalInBackground() {
    if (_fcmToken != null) {
      return; // Already have token
    }

    // Try again after 10 seconds
    Future.delayed(Duration(seconds: 10), () async {
      if (_fcmToken != null) {
        return; // Token was retrieved
      }

      print('🔄 Retrying FCM token retrieval in background...');
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            print('✅ APNS Token now available!');
          }
        }

        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          _fcmToken = token;
          print('');
          print('═══════════════════════════════════════════════════════');
          print('✅ FCM TOKEN RETRIEVED IN BACKGROUND!');
          print('═══════════════════════════════════════════════════════');
          print('🔑 Token: $token');
          print('═══════════════════════════════════════════════════════');
          print('');
        } else {
          // Try again after another delay
          _continueTokenRetrievalInBackground();
        }
      } catch (e) {
        print('⏳ Still waiting for FCM token: $e');
        // Try again after another delay
        _continueTokenRetrievalInBackground();
      }
    });
  }

  /// Configure message handlers for foreground, background, and terminated states
  void _configureMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Background message opened: ${message.messageId}');
      _handleBackgroundMessage(message);
    });

    // Check if app was opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📨 App opened from terminated state: ${message.messageId}');
        _handleTerminatedMessage(message);
      }
    });
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    await _showLocalNotification(message);

    // Emit notification data to stream
    _notificationController.add({
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'messageId': message.messageId,
    });
  }

  /// Handle background messages (app is in background)
  void _handleBackgroundMessage(RemoteMessage message) {
    // Navigate to specific screen based on notification data
    _notificationController.add({
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'messageId': message.messageId,
      'action': 'navigate',
    });
  }

  /// Handle terminated messages (app was closed)
  void _handleTerminatedMessage(RemoteMessage message) {
    // Navigate to specific screen based on notification data
    _notificationController.add({
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
      'messageId': message.messageId,
      'action': 'navigate',
    });
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'konnected_beauty_channel',
      'Konnected Beauty Notifications',
      channelDescription: 'Notifications for Konnected Beauty app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Manually retrieve FCM token (useful for testing)
  /// Returns the token or null if unavailable
  /// This will trigger a fresh attempt to get the token
  Future<String?> retrieveFCMToken() async {
    print('🔄 Manually retrieving FCM token...');
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Try to get APNS token first
        print('📱 Checking APNS token...');
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          print(
              '⚠️ APNS token not available. Testing on a real iOS device is recommended.');
          print('ℹ️ The token may become available after a few seconds.');
          // Start background retry
          _continueTokenRetrievalInBackground();
          return null;
        } else {
          final previewLength = apnsToken.length > 20 ? 20 : apnsToken.length;
          print(
              '✅ APNS Token available: ${apnsToken.substring(0, previewLength)}...');
        }
      }

      print('🔑 Getting FCM token...');
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken = token;
        print('');
        print('═══════════════════════════════════════════════════════');
        print('✅ FCM TOKEN RETRIEVED:');
        print('═══════════════════════════════════════════════════════');
        print(token);
        print('═══════════════════════════════════════════════════════');
        print('📋 Use this token in Firebase Console → Cloud Messaging');
        print('   → Send test message → Enter FCM registration token');
        print('═══════════════════════════════════════════════════════');
        print('');
      } else {
        print('⚠️ FCM token is null');
        // Start background retry
        _continueTokenRetrievalInBackground();
      }
      return token;
    } catch (e) {
      print('❌ Error retrieving FCM token: $e');
      if (e.toString().contains('apns-token-not-set')) {
        print('ℹ️ Note: On iOS Simulator, APNS token may not be available.');
        print('ℹ️ Please test on a real iOS device for full functionality.');
        print('ℹ️ Will continue trying in background...');
        // Start background retry
        _continueTokenRetrievalInBackground();
      }
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
  }
}

/// Top-level function for handling background messages
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('═══════════════════════════════════════════════════════');
  print('📨 BACKGROUND MESSAGE RECEIVED');
  print('═══════════════════════════════════════════════════════');
  print('📨 Message ID: ${message.messageId}');
  print('📨 From: ${message.from}');
  print('📨 Title: ${message.notification?.title}');
  print('📨 Body: ${message.notification?.body}');
  print('📨 Data: ${message.data}');
  print('📨 Sent Time: ${message.sentTime}');
  print('═══════════════════════════════════════════════════════');

  // Initialize Firebase if not already initialized
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('⚠️ Firebase already initialized or error: $e');
  }

  // Note: iOS automatically shows notifications in background
  // Android also shows them automatically if notification payload is present
  // Local notifications are only needed for data-only messages
  if (message.notification == null) {
    print('ℹ️ Data-only message received (no notification payload)');
    print('ℹ️ You may want to show a local notification here');
  } else {
    print('✅ Notification payload present - system will show it automatically');
  }
}
