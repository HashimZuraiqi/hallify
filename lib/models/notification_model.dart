import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for in-app notifications stored in Firestore
/// Replaces Firebase Cloud Messaging for completely free solution
class NotificationModel {
  final String id;
  final String to; // userId who receives the notification
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String? hallId; // Optional reference to hall
  final String? visitId; // Optional reference to visit request
  final String type; // 'visit_request', 'visit_approved', 'visit_rejected', 'message'

  NotificationModel({
    required this.id,
    required this.to,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
    this.hallId,
    this.visitId,
    this.type = 'general',
  });

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      to: data['to'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hallId: data['hallId'],
      visitId: data['visitId'],
      type: data['type'] ?? 'general',
    );
  }

  /// Create from Map
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      to: map['to'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hallId: map['hallId'],
      visitId: map['visitId'],
      type: map['type'] ?? 'general',
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'to': to,
      'title': title,
      'body': body,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      if (hallId != null) 'hallId': hallId,
      if (visitId != null) 'visitId': visitId,
      'type': type,
    };
  }

  /// Copy with modifications
  NotificationModel copyWith({
    String? id,
    String? to,
    String? title,
    String? body,
    bool? read,
    DateTime? createdAt,
    String? hallId,
    String? visitId,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      to: to ?? this.to,
      title: title ?? this.title,
      body: body ?? this.body,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      hallId: hallId ?? this.hallId,
      visitId: visitId ?? this.visitId,
      type: type ?? this.type,
    );
  }
}
