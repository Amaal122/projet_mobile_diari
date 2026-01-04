/// Notification Service
/// ====================
/// Handles push notifications using Firebase Cloud Messaging

import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Initialize FCM and request permissions
  static Future<void> initialize() async {
    try {
      // Request notification permissions (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional notification permission');
      } else {
        print('User declined notification permission');
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        // TODO: Send token to backend to update user profile
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (app opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Handle notification when app is terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Handle foreground message (app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    
    if (message.notification != null) {
      print('Title: ${message.notification!.title}');
      print('Body: ${message.notification!.body}');
      
      // You can show a local notification here or update UI
      // For now, just print to console
    }

    if (message.data.isNotEmpty) {
      print('Data: ${message.data}');
      // Handle data payload (e.g., navigate to specific screen)
    }
  }

  /// Handle background message (app opened from notification)
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message received: ${message.notification?.title}');
    
    if (message.data.isNotEmpty) {
      print('Data: ${message.data}');
      
      // Navigate based on notification type
      final type = message.data['type'];
      final id = message.data['id'];
      
      switch (type) {
        case 'order':
          // Navigate to order details
          print('Navigate to order: $id');
          break;
        case 'message':
          // Navigate to messages
          print('Navigate to message: $id');
          break;
        case 'review':
          // Navigate to reviews
          print('Navigate to review: $id');
          break;
        default:
          print('Unknown notification type: $type');
      }
    }
  }

  /// Subscribe to a topic (e.g., 'promotions', 'updates')
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Initialize Firebase if needed
  // await Firebase.initializeApp();
}
