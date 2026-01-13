import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking status
enum BookingStatus { confirmed, cancelled }

/// Represents a confirmed booking for a venue time slot.
/// Uses startAt/endAt timestamps for precise overlap detection.
class BookingModel {
  final String id;
  final String venueId;
  final String venueName;
  final String venueImageUrl;
  final String organizerId;
  final String organizerName;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final DateTime startAt;
  final DateTime endAt;
  final BookingStatus status;
  final String? chatRoomId;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;

  BookingModel({
    required this.id,
    required this.venueId,
    required this.venueName,
    this.venueImageUrl = '',
    required this.organizerId,
    required this.organizerName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone = '',
    required this.startAt,
    required this.endAt,
    this.status = BookingStatus.confirmed,
    this.chatRoomId,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
  });

  /// Create from Firestore document
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      venueName: data['venueName'] ?? '',
      venueImageUrl: data['venueImageUrl'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      startAt: (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (data['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      chatRoomId: data['chatRoomId'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'venueId': venueId,
      'venueName': venueName,
      'venueImageUrl': venueImageUrl,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status.name,
      'chatRoomId': chatRoomId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  /// Copy with modifications
  BookingModel copyWith({
    String? id,
    String? venueId,
    String? venueName,
    String? venueImageUrl,
    String? organizerId,
    String? organizerName,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    DateTime? startAt,
    DateTime? endAt,
    BookingStatus? status,
    String? chatRoomId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      venueImageUrl: venueImageUrl ?? this.venueImageUrl,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  /// Check if booking is confirmed
  bool get isConfirmed => status == BookingStatus.confirmed;

  /// Check if booking is cancelled
  bool get isCancelled => status == BookingStatus.cancelled;

  /// Check if booking is in the past
  bool get isPast => endAt.isBefore(DateTime.now());

  /// Check if booking is upcoming
  bool get isUpcoming => startAt.isAfter(DateTime.now());

  /// Check if booking is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startAt) && now.isBefore(endAt);
  }

  /// Get duration in minutes
  int get durationMinutes => endAt.difference(startAt).inMinutes;

  /// Get formatted date
  String get formattedDate {
    return '${startAt.day}/${startAt.month}/${startAt.year}';
  }

  /// Get formatted time range
  String get formattedTimeRange {
    final startHour = startAt.hour.toString().padLeft(2, '0');
    final startMin = startAt.minute.toString().padLeft(2, '0');
    final endHour = endAt.hour.toString().padLeft(2, '0');
    final endMin = endAt.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
  }

  /// Get formatted date and time
  String get formattedDateTime => '$formattedDate at $formattedTimeRange';

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  String toString() => 'BookingModel(id: $id, venueId: $venueId, status: $status)';

  @override
  bool operator ==(Object other) => identical(this, other) || (other is BookingModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Represents a generated time slot (not stored in DB)
class TimeSlot {
  final DateTime startAt;
  final DateTime endAt;
  final bool isAvailable;

  TimeSlot({
    required this.startAt,
    required this.endAt,
    this.isAvailable = true,
  });

  /// Get formatted time range
  String get formattedTimeRange {
    final startHour = startAt.hour.toString().padLeft(2, '0');
    final startMin = startAt.minute.toString().padLeft(2, '0');
    final endHour = endAt.hour.toString().padLeft(2, '0');
    final endMin = endAt.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
  }

  /// Check if this slot overlaps with a booking
  bool overlapsWithBooking(BookingModel booking) {
    return startAt.isBefore(booking.endAt) && endAt.isAfter(booking.startAt);
  }

  @override
  String toString() => 'TimeSlot($formattedTimeRange, available: $isAvailable)';
}
