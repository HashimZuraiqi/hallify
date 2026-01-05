import 'package:cloud_firestore/cloud_firestore.dart';

enum VisitStatus { pending, approved, rejected, completed, cancelled }

class VisitRequestModel {
  final String id;
  final String hallId;
  final String hallName;
  final String hallImageUrl;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String organizerId;
  final String organizerName;
  final DateTime visitDate;
  final String visitTime;
  final String? visitEndTime;
  final VisitStatus status;
  final String? message;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Aliases for consistency
  String get timeSlot => visitTime;
  String get notes => message ?? '';
  DateTime get requestDate => createdAt;

  VisitRequestModel({
    required this.id,
    required this.hallId,
    required this.hallName,
    this.hallImageUrl = '',
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone = '',
    required this.organizerId,
    required this.organizerName,
    required this.visitDate,
    required this.visitTime,
    this.visitEndTime,
    this.status = VisitStatus.pending,
    this.message,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create VisitRequestModel from Firestore document
  factory VisitRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitRequestModel(
      id: doc.id,
      hallId: data['hallId'] ?? '',
      hallName: data['hallName'] ?? '',
      hallImageUrl: data['hallImageUrl'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      visitTime: data['visitTime'] ?? '',
      visitEndTime: data['visitEndTime'],
      status: VisitStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => VisitStatus.pending,
      ),
      message: data['message'],
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create VisitRequestModel from Map
  factory VisitRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return VisitRequestModel(
      id: id,
      hallId: map['hallId'] ?? '',
      hallName: map['hallName'] ?? '',
      hallImageUrl: map['hallImageUrl'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      visitDate: (map['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      visitTime: map['visitTime'] ?? '',
      visitEndTime: map['visitEndTime'],
      status: VisitStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VisitStatus.pending,
      ),
      message: map['message'],
      rejectionReason: map['rejectionReason'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert VisitRequestModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'hallName': hallName,
      'hallImageUrl': hallImageUrl,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'visitDate': Timestamp.fromDate(visitDate),
      'visitTime': visitTime,
      'visitEndTime': visitEndTime,
      'status': status.name,
      'message': message,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  VisitRequestModel copyWith({
    String? id,
    String? hallId,
    String? hallName,
    String? hallImageUrl,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? organizerId,
    String? organizerName,
    DateTime? visitDate,
    String? visitTime,
    String? visitEndTime,
    VisitStatus? status,
    String? message,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitRequestModel(
      id: id ?? this.id,
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      hallImageUrl: hallImageUrl ?? this.hallImageUrl,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      visitDate: visitDate ?? this.visitDate,
      visitTime: visitTime ?? this.visitTime,
      visitEndTime: visitEndTime ?? this.visitEndTime,
      status: status ?? this.status,
      message: message ?? this.message,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if request is pending
  bool get isPending => status == VisitStatus.pending;

  /// Check if request is approved
  bool get isApproved => status == VisitStatus.approved;

  /// Check if request is rejected
  bool get isRejected => status == VisitStatus.rejected;

  /// Check if request is completed
  bool get isCompleted => status == VisitStatus.completed;

  /// Check if request is cancelled
  bool get isCancelled => status == VisitStatus.cancelled;

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case VisitStatus.pending:
        return 'Pending';
      case VisitStatus.approved:
        return 'Approved';
      case VisitStatus.rejected:
        return 'Rejected';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get formatted visit date and time
  String get formattedDateTime {
    final date = '${visitDate.day}/${visitDate.month}/${visitDate.year}';
    return '$date at $visitTime';
  }

  @override
  String toString() {
    return 'VisitRequestModel(id: $id, hallName: $hallName, status: $status, visitDate: $visitDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisitRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
