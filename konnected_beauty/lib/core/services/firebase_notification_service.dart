import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;
import 'storage/token_storage_service.dart';
import 'api/http_interceptor.dart';

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

  // Background retry tracking
  bool _isRetryingInBackground = false;
  int _backgroundRetryCount = 0;

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
        // On iOS, we need to wait for APNS token first
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          print('📱 iOS detected - waiting for APNS token...');
          print(
              'ℹ️ Testing on iOS Simulator? Push notifications require a REAL device!');
          print(
              'ℹ️ Make sure Push Notifications capability is enabled in Xcode');

          // Try to get APNS token first, then FCM token
          _waitForAPNSTokenAndGetFCMToken();
        } else {
          // Android - get token directly
          final initialDelay = Duration(seconds: 2);
          print(
              '⏳ Waiting ${initialDelay.inSeconds} seconds before attempting to get FCM token...');
          Future.delayed(initialDelay, () {
            _getFCMTokenWithRetry().catchError((error) {
              print('❌ Failed to get FCM token: $error');
            });
          });
        }
      } else {
        print('⚠️ Skipping FCM token retrieval - permission not granted');
        print('ℹ️ Token will be retrieved once user grants permission');
      }

      // Listen for APNS token availability (iOS only)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        _listenForAPNSToken();
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 === FCM TOKEN REFRESHED ===');
        print('🔄 New Token: $newToken');
        _fcmToken = newToken;

        // Automatically send refreshed token to backend
        try {
          final userRole = await TokenStorageService.getUserRole();
          if (userRole != null && userRole.isNotEmpty) {
            print('🔄 Sending refreshed token to backend for role: $userRole');
            final result = await HttpInterceptor.registerFCMToken(
              token: newToken,
              userRole: userRole,
            );
            if (result['success'] == true) {
              print('✅ Refreshed FCM token registered successfully');
            } else {
              print(
                  '❌ Failed to register refreshed FCM token: ${result['message']}');
            }
          } else {
            print('⚠️ User role not available, skipping token registration');
          }
        } catch (e) {
          print('❌ Error registering refreshed FCM token: $e');
        }
      });
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Listen for APNS token availability (iOS only)
  /// This periodically checks if the APNS token becomes available
  void _listenForAPNSToken() {
    print('📱 === STARTING APNS TOKEN LISTENER ===');

    // Check every 10 seconds if APNS token is available
    Timer.periodic(Duration(seconds: 10), (timer) async {
      // Stop if we already have FCM token
      if (_fcmToken != null) {
        print('✅ FCM token already available, stopping APNS listener');
        timer.cancel();
        return;
      }

      try {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          print('');
          print('═══════════════════════════════════════════════════════');
          print('✅ APNS TOKEN DETECTED BY LISTENER!');
          print('═══════════════════════════════════════════════════════');
          print('🔑 APNS Token: ${apnsToken.substring(0, 20)}...');
          print('═══════════════════════════════════════════════════════');
          print('');

          // Stop the timer
          timer.cancel();

          // Now get FCM token
          try {
            final fcmToken = await _firebaseMessaging.getToken();
            if (fcmToken != null) {
              _fcmToken = fcmToken;
              print('');
              print('═══════════════════════════════════════════════════════');
              print('✅ FCM TOKEN RETRIEVED VIA LISTENER!');
              print('═══════════════════════════════════════════════════════');
              print('🔑 Token: $fcmToken');
              print('═══════════════════════════════════════════════════════');
              print('');

              // Automatically send token to backend if user is logged in
              _sendTokenToBackendIfLoggedIn(fcmToken);
            }
          } catch (e) {
            print('❌ Error getting FCM token after APNS detected: $e');
          }
        } else {
          print('⏳ APNS token still not available (listener check)...');
          print(
              '📱 Check Xcode console for: "APNS TOKEN RECEIVED IN APPDELEGATE"');
        }
      } catch (e) {
        print('⏳ Error checking APNS token in listener: $e');
      }
    });
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
            print(
                '⚠️ IMPORTANT: Push notifications require a REAL iOS device!');
            print('⚠️ iOS Simulator does NOT support push notifications');
            if (attempt < maxRetries) {
              // Wait before retrying (longer delays for later attempts)
              final delay = attempt * 3;
              print('⏳ Waiting $delay seconds before retry...');
              await Future.delayed(Duration(seconds: delay));
              continue;
            } else {
              print('⚠️ APNS Token not available after $maxRetries attempts');
              print('⚠️ Please check:');
              print(
                  '   1. Are you testing on a REAL iOS device? (Not Simulator)');
              print('   2. Is Push Notifications capability enabled in Xcode?');
              print(
                  '   3. Is APNS certificate configured in Firebase Console?');
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

        // Automatically send token to backend if user is logged in
        _sendTokenToBackendIfLoggedIn(_fcmToken!);

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

  /// Wait for APNS token and then get FCM token (iOS specific)
  Future<void> _waitForAPNSTokenAndGetFCMToken() async {
    print('📱 === WAITING FOR APNS TOKEN (iOS) ===');
    print('ℹ️ Important: Push notifications require a REAL iOS device');
    print('ℹ️ iOS Simulator does NOT support push notifications');
    print('ℹ️ Waiting for AppDelegate to receive APNS token...');

    // Wait longer for AppDelegate to register and receive APNS token
    // AppDelegate calls registerForRemoteNotifications() which triggers
    // didRegisterForRemoteNotificationsWithDeviceToken callback
    await Future.delayed(Duration(seconds: 3));

    // Try to get APNS token with multiple attempts
    // The APNS token is set by AppDelegate in didRegisterForRemoteNotificationsWithDeviceToken
    String? apnsToken;
    for (int attempt = 1; attempt <= 15; attempt++) {
      try {
        print('📱 Checking for APNS token (attempt $attempt/15)...');
        print(
            '📱 Make sure AppDelegate received the token (check logs for "APNS token received in AppDelegate")');

        apnsToken = await _firebaseMessaging.getAPNSToken();

        if (apnsToken != null) {
          final previewLength = apnsToken.length > 20 ? 20 : apnsToken.length;
          print('═══════════════════════════════════════════════════════');
          print(
              '✅ APNS Token received in Dart: ${apnsToken.substring(0, previewLength)}...');
          print('✅ Full APNS Token: $apnsToken');
          print('═══════════════════════════════════════════════════════');
          break;
        } else {
          print('⏳ APNS Token not available yet (attempt $attempt/15)...');
          print('⏳ This means AppDelegate has not received the token yet');
          print(
              '⏳ Check Xcode console for: "APNS token received in AppDelegate"');
          if (attempt < 15) {
            // Wait longer between attempts (5 seconds)
            await Future.delayed(Duration(seconds: 5));
          }
        }
      } catch (e) {
        print('⏳ Error checking APNS token: $e');
        if (attempt < 15) {
          await Future.delayed(Duration(seconds: 5));
        }
      }
    }

    if (apnsToken == null) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('⚠️ APNS Token not available after 15 attempts');
      print('═══════════════════════════════════════════════════════');
      print('⚠️ This usually means:');
      print('   1. App is running on iOS Simulator (use REAL device)');
      print('   2. Push Notifications capability not enabled in Xcode');
      print('   3. APNS certificate not configured in Firebase Console');
      print('   4. App needs to be in foreground');
      print('');
      print('🔍 DIAGNOSTIC STEPS:');
      print(
          '   1. Check Xcode console for: "APNS TOKEN RECEIVED IN APPDELEGATE"');
      print(
          '   2. If you see that log, the token is received but not passed to Firebase');
      print(
          '   3. If you DON\'T see that log, AppDelegate is not receiving the token');
      print('   4. Verify Push Notifications capability in Xcode');
      print('   5. Verify APNS certificate/key in Firebase Console');
      print('═══════════════════════════════════════════════════════');
      print('');
      print('ℹ️ Will continue trying in background...');
      _continueTokenRetrievalInBackground();
      return;
    }

    // Now get FCM token
    print('🔑 APNS token available, getting FCM token...');
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('');
        print('═══════════════════════════════════════════════════════');
        print('✅ FCM TOKEN SUCCESSFULLY RETRIEVED (iOS)!');
        print('═══════════════════════════════════════════════════════');
        print('🔑 Token: $_fcmToken');
        print('═══════════════════════════════════════════════════════');
        print('');

        // Automatically send token to backend if user is logged in
        _sendTokenToBackendIfLoggedIn(_fcmToken!);
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      _continueTokenRetrievalInBackground();
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

    if (_isRetryingInBackground) {
      print('⏭️ Background retry already in progress, skipping...');
      return;
    }

    _isRetryingInBackground = true;
    _backgroundRetryCount++;

    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔄 Background retry #$_backgroundRetryCount (unlimited)');
    print('═══════════════════════════════════════════════════════');
    print('ℹ️ Will keep trying until APNS token is available');
    print('ℹ️ The listener is also checking every 10 seconds');
    print('═══════════════════════════════════════════════════════');

    // Try again after 15 seconds (longer delay to avoid spam)
    Future.delayed(Duration(seconds: 15), () async {
      if (_fcmToken != null) {
        _isRetryingInBackground = false;
        _backgroundRetryCount = 0;
        return; // Token was retrieved
      }

      // Continue retrying indefinitely (the listener will also help)
      if (_backgroundRetryCount % 10 == 0) {
        // Every 10 retries, print a diagnostic message
        print('');
        print('═══════════════════════════════════════════════════════');
        print(
            '⚠️ Still waiting for APNS token (attempt $_backgroundRetryCount)');
        print('═══════════════════════════════════════════════════════');
        print('');
        print('🔍 CHECK XCODE CONSOLE FOR:');
        print('   "APNS TOKEN RECEIVED IN APPDELEGATE"');
        print('');
        print(
            'If you see that log, the token is received but not passed to Firebase');
        print(
            'If you DON\'T see that log, AppDelegate is not receiving the token');
        print('');
        print('Common issues:');
        print('  1. Push Notifications capability not enabled in Xcode');
        print('  2. APNS certificate/key not configured in Firebase Console');
        print('  3. App running on iOS Simulator (use REAL device)');
        print('  4. Network connectivity issues');
        print('═══════════════════════════════════════════════════════');
        print('');
      }

      print('🔄 Retrying FCM token retrieval in background...');
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            print('✅ APNS Token now available!');
            print('🔑 APNS Token: ${apnsToken.substring(0, 20)}...');
          } else {
            print(
                '⏳ Still waiting for FCM token: [firebase_messaging/apns-token-not-set] APNS token has not been set yet. Please ensure the APNS token is available by calling `getAPNSToken()`.');
            print(
                '📱 Check Xcode console for: "APNS TOKEN RECEIVED IN APPDELEGATE"');
            // Continue retrying
            _isRetryingInBackground = false;
            _continueTokenRetrievalInBackground();
            return;
          }
        }

        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          _fcmToken = token;
          _isRetryingInBackground = false;
          _backgroundRetryCount = 0;
          print('');
          print('═══════════════════════════════════════════════════════');
          print('✅ FCM TOKEN RETRIEVED IN BACKGROUND!');
          print('═══════════════════════════════════════════════════════');
          print('🔑 Token: $token');
          print('═══════════════════════════════════════════════════════');
          print('');

          // Automatically send token to backend if user is logged in
          _sendTokenToBackendIfLoggedIn(token);
        } else {
          // Try again after another delay
          _isRetryingInBackground = false;
          _continueTokenRetrievalInBackground();
        }
      } catch (e) {
        print('⏳ Still waiting for FCM token: $e');
        // Try again after another delay
        _isRetryingInBackground = false;
        _continueTokenRetrievalInBackground();
      }
    });
  }

  /// Configure message handlers for foreground, background, and terminated states
  void _configureMessageHandlers() {
    print('🔔 === CONFIGURING MESSAGE HANDLERS ===');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('═══════════════════════════════════════════════════════');
      print('📨 === FOREGROUND MESSAGE RECEIVED ===');
      print('📨 Message ID: ${message.messageId}');
      print('📨 From: ${message.from}');
      print('📨 Title: ${message.notification?.title}');
      print('📨 Body: ${message.notification?.body}');
      print('📨 Data: ${message.data}');
      print('📨 Sent Time: ${message.sentTime}');
      print('═══════════════════════════════════════════════════════');
      _handleForegroundMessage(message);
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('═══════════════════════════════════════════════════════');
      print('📨 === BACKGROUND MESSAGE OPENED ===');
      print('📨 Message ID: ${message.messageId}');
      print('📨 From: ${message.from}');
      print('📨 Title: ${message.notification?.title}');
      print('📨 Body: ${message.notification?.body}');
      print('📨 Data: ${message.data}');
      print('═══════════════════════════════════════════════════════');
      _handleBackgroundMessage(message);
    });

    // Check if app was opened from a terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('═══════════════════════════════════════════════════════');
        print('📨 === APP OPENED FROM TERMINATED STATE ===');
        print('📨 Message ID: ${message.messageId}');
        print('📨 Title: ${message.notification?.title}');
        print('📨 Body: ${message.notification?.body}');
        print('📨 Data: ${message.data}');
        print('═══════════════════════════════════════════════════════');
        _handleTerminatedMessage(message);
      } else {
        print('ℹ️ No initial message (app was not opened from notification)');
      }
    });

    print('✅ Message handlers configured successfully');
    print('🔔 === END CONFIGURING MESSAGE HANDLERS ===');
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 === HANDLING FOREGROUND MESSAGE ===');
    print('📨 Message ID: ${message.messageId}');
    print('📨 Title: ${message.notification?.title}');
    print('📨 Body: ${message.notification?.body}');
    print('📨 Data: ${message.data}');
    print('📨 Notification: ${message.notification}');
    print('📨 === END FOREGROUND MESSAGE ===');

    // Show local notification when app is in foreground
    try {
      await _showLocalNotification(message);
      print('✅ Local notification shown successfully');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }

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
    print('📨 === HANDLING BACKGROUND MESSAGE ===');
    print('📨 Message ID: ${message.messageId}');
    print('📨 Title: ${message.notification?.title}');
    print('📨 Body: ${message.notification?.body}');
    print('📨 Data: ${message.data}');
    print('📨 === END BACKGROUND MESSAGE ===');

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
    print('🔔 === SHOWING LOCAL NOTIFICATION ===');
    print('🔔 Title: ${message.notification?.title}');
    print('🔔 Body: ${message.notification?.body}');

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
      interruptionLevel: InterruptionLevel.active, // Important for iOS
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? '',
        notificationDetails,
        payload: message.data.toString(),
      );
      print('✅ Local notification displayed successfully');
    } catch (e) {
      print('❌ Error displaying local notification: $e');
      print('❌ Error details: ${e.toString()}');
      rethrow;
    }
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

        // Automatically send token to backend if user is logged in
        _sendTokenToBackendIfLoggedIn(token);
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

  /// Send FCM token to backend if user is logged in
  Future<void> _sendTokenToBackendIfLoggedIn(String token) async {
    try {
      final userRole = await TokenStorageService.getUserRole();
      if (userRole != null && userRole.isNotEmpty) {
        print('📱 === AUTO-REGISTERING FCM TOKEN ===');
        print('👤 User Role: $userRole');
        print('🔑 Token: ${token.substring(0, 20)}...');

        final result = await HttpInterceptor.registerFCMToken(
          token: token,
          userRole: userRole,
        );

        if (result['success'] == true) {
          print('✅ FCM token auto-registered successfully');
        } else {
          print('❌ Failed to auto-register FCM token: ${result['message']}');
        }
      } else {
        print('ℹ️ User not logged in, skipping FCM token registration');
        print('ℹ️ Token will be registered after login');
      }
    } catch (e) {
      print('❌ Error auto-registering FCM token: $e');
      // Don't throw - this is a background operation
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

  // On iOS, notifications with notification payload are automatically shown by the system
  // On Android, they are also shown automatically if notification payload is present
  // Local notifications are only needed for data-only messages

  if (message.notification == null) {
    print('ℹ️ Data-only message received (no notification payload)');
    print('ℹ️ For iOS: System will not show notification automatically');
    print('ℹ️ You may want to show a local notification here');
  } else {
    print('✅ Notification payload present');
    print('✅ iOS: System will show notification automatically');
    print('✅ Android: System will show notification automatically');

    // For iOS, ensure the notification is properly handled
    // The system should display it automatically, but we log it for debugging
    print('📨 Notification Title: ${message.notification?.title}');
    print('📨 Notification Body: ${message.notification?.body}');
  }
}
