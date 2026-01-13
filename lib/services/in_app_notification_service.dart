import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// In-app notification service using Firestore
/// Replaces Firebase Cloud Messaging for completely free solution
class InAppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');

  /// Create a new notification
  Future<String> createNotification({
    required String to,
    required String title,
    required String body,
    String? hallId,
    String? visitId,
    String type = 'general',
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        to: to,
        title: title,
        body: body,
        read: false,
        createdAt: DateTime.now(),
        hallId: hallId,
        visitId: visitId,
        type: type,
      );

      final docRef = await _notificationsCollection.add(notification.toMap());
      print('Notification created: $title → User: $to');
      return docRef.id;
    } catch (e) {
      print('Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get user notifications stream (real-time)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationsCollection
        .where('to', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Get unread notifications count stream
  Stream<int> getUnreadCount(String userId) {
    return _notificationsCollection
        .where('to', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all user notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadDocs = await _notificationsCollection
          .where('to', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Delete all user notifications
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final userDocs = await _notificationsCollection
          .where('to', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in userDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // ==================== SPECIFIC NOTIFICATION TYPES ====================

  /// Send visit request notification to organizer
  Future<void> sendVisitRequestNotification({
    required String organizerId,
    required String customerName,
    required String hallName,
    required String visitDate,
    required String visitTime,
    required String visitId,
    required String hallId,
  }) async {
    await createNotification(
      to: organizerId,
      title: 'New Visit Request',
      body: '$customerName requested to visit $hallName on $visitDate at $visitTime',
      hallId: hallId,
      visitId: visitId,
      type: 'visit_request',
    );
  }

  /// Send visit approved notification to customer
  Future<void> sendVisitApprovedNotification({
    required String customerId,
    required String hallName,
    required String visitDate,
    required String visitTime,
    required String visitId,
    required String hallId,
  }) async {
    await createNotification(
      to: customerId,
      title: 'Visit Approved ✓',
      body: 'Your visit to $hallName on $visitDate at $visitTime has been approved!',
      hallId: hallId,
      visitId: visitId,
      type: 'visit_approved',
    );
  }

  /// Send visit rejected notification to customer
  Future<void> sendVisitRejectedNotification({
    required String customerId,
    required String hallName,
    required String reason,
    required String visitId,
    required String hallId,
  }) async {
    final reasonText = reason.isNotEmpty ? ' Reason: $reason' : '';
    await createNotification(
      to: customerId,
      title: 'Visit Request Declined',
      body: 'Your visit request for $hallName was declined.$reasonText',
      hallId: hallId,
      visitId: visitId,
      type: 'visit_rejected',
    );
  }

  /// Send visit completed notification to customer
  Future<void> sendVisitCompletedNotification({
    required String customerId,
    required String hallName,
    required String visitId,
    required String hallId,
  })async {
    await createNotification(
      to: customerId,
      title: 'Visit Completed',
      body: 'Your visit to $hallName has been marked as completed. Don\'t forget to leave a review!',
      hallId: hallId,
      visitId: visitId,
      type: 'visit_completed',
    );
  }

  /// Send new message notification
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String message,
  }) async {
    final truncatedMessage = message.length > 100 
        ? '${message.substring(0, 100)}...' 
        : message;
    
    await createNotification(
      to: receiverId,
      title: 'New message from $senderName',
      body: truncatedMessage,
      type: 'message',
    );
  }

  // ==================== BACKWARD COMPATIBILITY ALIASES ====================

  /// Alias for sendVisitRequestNotification (backward compatibility)
  Future<void> sendTimeSlotRequestNotification({
    required String organizerFcmToken,
    required String customerName,
    required String hallName,
    required String visitDate,
    required String visitTime,
    String? visitId,
    String? hallId,
  }) async {
    await sendVisitRequestNotification(
      organizerId: organizerFcmToken, // Treat as organizerId
      customerName: customerName,
      hallName: hallName,
      visitDate: visitDate,
      visitTime: visitTime,
      visitId: visitId ?? '',
      hallId: hallId ?? '',
    );
  }

  /// Alias for sendVisitApprovedNotification (backward compatibility)
  Future<void> sendTimeSlotApprovalNotification({
    required String customerFcmToken,
    required String hallName,
    required String visitDate,
    required String visitTime,
    String? visitId,
    String? hallId,
  }) async {
    await sendVisitApprovedNotification(
      customerId: customerFcmToken, // Treat as customerId
      hallName: hallName,
      visitDate: visitDate,
      visitTime: visitTime,
      visitId: visitId ?? '',
      hallId: hallId ?? '',
    );
  }

  /// Alias for sendVisitRejectedNotification (backward compatibility)
  Future<void> sendTimeSlotRejectionNotification({
    required String customerFcmToken,
    required String hallName,
    required String reason,
    String? visitId,
    String? hallId,
  }) async {
    await sendVisitRejectedNotification(
      customerId: customerFcmToken, // Treat as customerId
      hallName: hallName,
      reason: reason,
      visitId: visitId ?? '',
      hallId: hallId ?? '',
    );
  }
}

