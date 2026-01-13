import 'package:cloud_firestore/cloud_firestore.dart';

class HallSlotModel {
  final String hallId;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm
  final bool booked;
  final String? visitId;
  final String? organizerId;
  final String? customerId;
  final DateTime createdAt;

  HallSlotModel({
    required this.hallId,
    required this.date,
    required this.time,
    required this.booked,
    this.visitId,
    this.organizerId,
    this.customerId,
    required this.createdAt,
  });

  /// Generate slot ID from components
  static String generateId(String hallId, String date, String time) {
    return '${hallId}_${date}_$time';
  }

  /// Get slot ID for this model
  String get id => generateId(hallId, date, time);

  /// Create from Firestore
  factory HallSlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HallSlotModel(
      hallId: data['hallId'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      booked: data['booked'] ?? false,
      visitId: data['visitId'],
      organizerId: data['organizerId'],
      customerId: data['customerId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'date': date,
      'time': time,
      'booked': booked,
      'visitId': visitId,
      'organizerId': organizerId,
      'customerId': customerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Display time range
  String get displayTime => time;
}
