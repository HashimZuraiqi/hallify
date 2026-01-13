import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilitySlotModel {
  final String id;
  final String hallId;
  final String date; // yyyy-MM-dd format
  final String startTime; // HH:mm format (e.g., "10:00")
  final String endTime; // HH:mm format (e.g., "11:00")
  final int duration; // minutes
  final bool isAvailable;
  final String? bookedBy; // userId when booked
  final String? visitId; // visitRequestId when approved
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilitySlotModel({
    required this.id,
    required this.hallId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.isAvailable,
    this.bookedBy,
    this.visitId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory AvailabilitySlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AvailabilitySlotModel(
      id: doc.id,
      hallId: data['hallId'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      duration: data['duration'] ?? 60,
      isAvailable: data['isAvailable'] ?? true,
      bookedBy: data['bookedBy'],
      visitId: data['visitId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'isAvailable': isAvailable,
      'bookedBy': bookedBy,
      'visitId': visitId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get display time range (e.g., "10:00 - 11:00")
  String get timeRange => '$startTime - $endTime';

  /// Copy with modifications
  AvailabilitySlotModel copyWith({
    String? id,
    String? hallId,
    String? date,
    String? startTime,
    String? endTime,
    int? duration,
    bool? isAvailable,
    String? bookedBy,
    String? visitId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilitySlotModel(
      id: id ?? this.id,
      hallId: hallId ?? this.hallId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isAvailable: isAvailable ?? this.isAvailable,
      bookedBy: bookedBy ?? this.bookedBy,
      visitId: visitId ?? this.visitId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
