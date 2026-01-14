import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/in_app_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final InAppNotificationService _notificationService = InAppNotificationService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription<List<NotificationModel>>? _notificationsSub;
  StreamSubscription<int>? _unreadCountSub;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  /// Start listening to notifications for a user
  void startListening(String userId) {
    // Cancel existing subscriptions
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();

    _isLoading = true;
    notifyListeners();

    // Listen to notifications
    _notificationsSub = _notificationService.getUserNotifications(userId).listen(
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error loading notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );

    // Listen to unread count
    _unreadCountSub = _notificationService.getUnreadCount(userId).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
    );
  }

  /// Stop listening (call on logout)
  void stopListening() {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    await _notificationService.markAllAsRead(userId);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(notificationId);
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    await _notificationService.deleteAllUserNotifications(userId);
  }

  @override
  void dispose() {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();
    super.dispose();
  }
}
