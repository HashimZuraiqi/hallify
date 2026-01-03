import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _requestPermission();

    // Set up Firebase Messaging handlers
    _setupFirebaseMessaging();

    _isInitialized = true;
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission: ${settings.authorizationStatus}');
  }

  /// Set up Firebase Messaging handlers
  void _setupFirebaseMessaging() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    // Foreground notifications will be handled by Firebase Messaging
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Handle navigation based on message data
    // This can be extended to navigate to specific screens
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Listen to token refresh
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Show a custom notification (simplified without local notifications)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Notifications will be handled by Firebase Messaging directly
    print('Notification: $title - $body');
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
    }
  }

  /// Send notification to a specific user (via FCM token)
  /// Note: In production, this should be done via a backend server
  /// This is a simplified version for demonstration
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // In production, use Firebase Admin SDK on your backend
    // This is just a placeholder for the notification flow
    print('Sending notification to: $fcmToken');
    print('Title: $title');
    print('Body: $body');
    
    // The actual implementation would call your backend API
    // which would use Firebase Admin SDK to send the notification
  }

  /// Send visit request notification to organizer
  Future<void> sendVisitRequestNotification({
    required String organizerFcmToken,
    required String customerName,
    required String hallName,
    required String visitDate,
  }) async {
    await sendPushNotification(
      fcmToken: organizerFcmToken,
      title: 'New Visit Request',
      body: '$customerName requested to visit $hallName on $visitDate',
      data: {
        'type': 'visit_request',
        'hallName': hallName,
      },
    );
  }

  /// Send visit status update notification to customer
  Future<void> sendVisitStatusNotification({
    required String customerFcmToken,
    required String hallName,
    required String status,
    String? reason,
  }) async {
    String body;
    if (status == 'approved') {
      body = 'Your visit request for $hallName has been approved!';
    } else {
      body = 'Your visit request for $hallName has been rejected.${reason != null ? ' Reason: $reason' : ''}';
    }

    await sendPushNotification(
      fcmToken: customerFcmToken,
      title: 'Visit Request Update',
      body: body,
      data: {
        'type': 'visit_status',
        'status': status,
        'hallName': hallName,
      },
    );
  }

  /// Send new message notification
  Future<void> sendMessageNotification({
    required String receiverFcmToken,
    required String senderName,
    required String message,
  }) async {
    await sendPushNotification(
      fcmToken: receiverFcmToken,
      title: 'New Message from $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      data: {
        'type': 'new_message',
        'senderName': senderName,
      },
    );
  }
}
