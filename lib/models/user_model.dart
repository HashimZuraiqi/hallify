import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, organizer }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? profileImageUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Alias for consistency
  String get id => uid;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.customer,
      ),
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      phone: map['phone'],
      profileImageUrl: map['profileImageUrl'],
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? profileImageUrl,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is an organizer
  bool get isOrganizer => role == UserRole.organizer;

  /// Check if user is a customer
  bool get isCustomer => role == UserRole.customer;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
