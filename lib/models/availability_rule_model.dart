import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of availability rule
enum RuleType { weekly, specificDate }

/// Represents an organizer-defined availability rule for a venue.
/// Rules define when a venue is available for booking.
/// Slots are generated at runtime from these rules - never stored.
class AvailabilityRuleModel {
  final String id;
  final String venueId;
  final RuleType type;
  final int? weekday; // 1=Monday, 2=Tuesday, ..., 7=Sunday (Dart standard)
  final DateTime? date; // For specific_date rules
  final String startTime; // "09:00" format
  final String endTime; // "18:00" format
  final int slotDurationMinutes; // 30, 60, 90, etc.
  final int bufferMinutes; // Buffer between bookings
  final bool isBlocked; // true = day is blocked, false = day is available
  final DateTime createdAt;
  final DateTime? updatedAt;

  AvailabilityRuleModel({
    required this.id,
    required this.venueId,
    required this.type,
    this.weekday,
    this.date,
    required this.startTime,
    required this.endTime,
    this.slotDurationMinutes = 60,
    this.bufferMinutes = 0,
    this.isBlocked = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory AvailabilityRuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AvailabilityRuleModel(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      type: RuleType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RuleType.weekly,
      ),
      weekday: data['weekday'],
      date: (data['date'] as Timestamp?)?.toDate(),
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '18:00',
      slotDurationMinutes: data['slotDurationMinutes'] ?? 60,
      bufferMinutes: data['bufferMinutes'] ?? 0,
      isBlocked: data['isBlocked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'type': type.name,
      'weekday': weekday,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'startTime': startTime,
      'endTime': endTime,
      'slotDurationMinutes': slotDurationMinutes,
      'bufferMinutes': bufferMinutes,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Copy with modifications
  AvailabilityRuleModel copyWith({
    String? id,
    String? venueId,
    RuleType? type,
    int? weekday,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? slotDurationMinutes,
    int? bufferMinutes,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AvailabilityRuleModel(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      type: type ?? this.type,
      weekday: weekday ?? this.weekday,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get weekday name
  String get weekdayName {
    if (weekday == null || weekday! < 1 || weekday! > 7) return '';
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday!];
  }

  /// Get formatted time range
  String get timeRange => '$startTime - $endTime';

  @override
  String toString() => 'AvailabilityRuleModel(id: $id, venueId: $venueId, type: $type)';

  @override
  bool operator ==(Object other) => identical(this, other) || (other is AvailabilityRuleModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
