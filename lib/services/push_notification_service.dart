/// Push Notification Service
/// ==========================
/// Handles FCM push notifications for orders
/// Chef receives new order alerts, customer gets status updates

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool _isInitialized = false;
  static String? _fcmToken;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('Notification permission not granted');
        return;
      }

      // Initialize local notifications
      await _initLocalNotifications();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token refreshed: $token');
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.notification?.title}');
    
    // Show local notification
    await showLocalNotification(
      title: message.notification?.title ?? 'Diari',
      body: message.notification?.body ?? '',
      payload: message.data['orderId'] ?? '',
    );
  }

  /// Handle message opened app
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
    // Navigate to order details if orderId present
    // This would typically use a navigation service
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigate to order details
  }

  /// Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'diari_orders',
      'Order Notifications',
      channelDescription: 'Notifications for order updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Save FCM token to user document
  static Future<void> saveTokenToUser(String userId) async {
    if (_fcmToken == null) {
      _fcmToken = await _messaging.getToken();
    }
    
    if (_fcmToken == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Save FCM token for chef
  static Future<void> saveTokenToChef(String chefId) async {
    if (_fcmToken == null) {
      _fcmToken = await _messaging.getToken();
    }
    
    if (_fcmToken == null) return;

    try {
      await _db.collection('cookers').doc(chefId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving FCM token for chef: $e');
    }
  }

  /// Subscribe to chef orders topic
  static Future<void> subscribeToChefOrders(String chefId) async {
    try {
      await _messaging.subscribeToTopic('chef_$chefId');
      debugPrint('Subscribed to chef orders topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from chef orders topic
  static Future<void> unsubscribeFromChefOrders(String chefId) async {
    try {
      await _messaging.unsubscribeFromTopic('chef_$chefId');
      debugPrint('Unsubscribed from chef orders topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;
}

/// Notification types for the app
enum NotificationType {
  newOrder,
  orderAccepted,
  orderPreparing,
  orderReady,
  orderDelivered,
  orderCancelled,
  newReview,
  promotion,
}

/// Create notification data for an order event
class OrderNotificationData {
  static Map<String, String> newOrderNotification({
    required String orderId,
    required String customerName,
    required int itemCount,
    required double total,
  }) {
    return {
      'title': 'طلب جديد! 🍽️',
      'body': '$customerName طلب $itemCount أصناف - ${total.toStringAsFixed(2)} دت',
      'orderId': orderId,
      'type': 'new_order',
    };
  }

  static Map<String, String> orderAcceptedNotification({
    required String orderId,
    required String chefName,
  }) {
    return {
      'title': 'تم قبول طلبك ✅',
      'body': '$chefName قبل طلبك وسيبدأ التحضير قريباً',
      'orderId': orderId,
      'type': 'order_accepted',
    };
  }

  static Map<String, String> orderPreparingNotification({
    required String orderId,
    required String chefName,
  }) {
    return {
      'title': 'جاري تحضير طلبك 👨‍🍳',
      'body': '$chefName يحضر طلبك الآن',
      'orderId': orderId,
      'type': 'order_preparing',
    };
  }

  static Map<String, String> orderReadyNotification({
    required String orderId,
    required String chefName,
  }) {
    return {
      'title': 'طلبك جاهز! 🎉',
      'body': 'طلبك من $chefName جاهز للتوصيل',
      'orderId': orderId,
      'type': 'order_ready',
    };
  }

  static Map<String, String> orderDeliveredNotification({
    required String orderId,
  }) {
    return {
      'title': 'تم التوصيل بنجاح ✅',
      'body': 'نتمنى لك وجبة شهية! لا تنسى تقييم الطباخ',
      'orderId': orderId,
      'type': 'order_delivered',
    };
  }
}
