import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  late FlutterLocalNotificationsPlugin _localNotifications;

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    _initializeLocalNotifications();

    // Request permission
    await _requestPermission();

    // Set up Firebase Messaging handlers
    _setupFirebaseMessaging();

    _isInitialized = true;
  }

  /// Initialize flutter local notifications
  void _initializeLocalNotifications() {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _localNotifications.initialize(initSettings);
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

  /// Show a custom local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hallify_notifications',
      'Hallify Notifications',
      channelDescription: 'Notifications for Hallify app',
      importance: Importance.max,
      priority: Priority.high,
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
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

  /// Send a push notification via FCM (placeholder - implement on backend)
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // In production, this should be called from your backend via Firebase Admin SDK
    // This is a placeholder showing the structure
    print('FCM Notification (backend):');
    print('Token: $fcmToken');
    print('Title: $title');
    print('Body: $body');
    if (data != null) {
      print('Data: $data');
    }
  }

  /// Send new message notification (only to receiver via FCM, not local)
  Future<void> sendMessageNotification({
    required String receiverFcmToken,
    required String senderName,
    required String message,
  }) async {
    final truncatedMessage = message.length > 100 ? '${message.substring(0, 100)}...' : message;
    
    // Only send via FCM to the receiver's device - don't show local notification
    // as this method is called on the sender's device
    await sendPushNotification(
      fcmToken: receiverFcmToken,
      title: 'New Message from $senderName',
      body: truncatedMessage,
      data: {
        'type': 'new_message',
        'senderName': senderName,
      },
    );
  }

  /// Send time slot request notification to organizer
  Future<void> sendTimeSlotRequestNotification({
    required String organizerFcmToken,
    required String customerName,
    required String hallName,
    required String visitDate,
    required String visitTime,
  }) async {
    final message = '$customerName requested to visit $hallName on $visitDate at $visitTime';
    
    // Show local notification
    await showLocalNotification(
      title: 'New Time Slot Request',
      body: message,
      payload: 'visit_request_notification',
    );
    
    // Also send via FCM
    await sendPushNotification(
      fcmToken: organizerFcmToken,
      title: 'New Time Slot Request',
      body: message,
      data: {
        'type': 'visit_request',
        'hallName': hallName,
        'customerName': customerName,
      },
    );
  }

  /// Send time slot approval notification to customer
  Future<void> sendTimeSlotApprovalNotification({
    required String customerFcmToken,
    required String hallName,
    required String visitDate,
    required String visitTime,
  }) async {
    final message = 'Your visit request for $hallName on $visitDate at $visitTime has been approved!';
    
    // Show local notification
    await showLocalNotification(
      title: 'Time Slot Approved',
      body: message,
      payload: 'visit_approval_notification',
    );
    
    // Also send via FCM
    await sendPushNotification(
      fcmToken: customerFcmToken,
      title: 'Time Slot Approved',
      body: message,
      data: {
        'type': 'visit_status',
        'status': 'approved',
        'hallName': hallName,
      },
    );
  }

  /// Send time slot rejection notification to customer
  Future<void> sendTimeSlotRejectionNotification({
    required String customerFcmToken,
    required String hallName,
    required String reason,
  }) async {
    final message = 'Your visit request for $hallName has been declined.${reason.isNotEmpty ? ' Reason: $reason' : ''}';
    
    // Show local notification
    await showLocalNotification(
      title: 'Time Slot Declined',
      body: message,
      payload: 'visit_rejection_notification',
    );
    
    // Also send via FCM
    await sendPushNotification(
      fcmToken: customerFcmToken,
      title: 'Time Slot Declined',
      body: message,
      data: {
        'type': 'visit_status',
        'status': 'rejected',
        'hallName': hallName,
      },
    );
  }
}
