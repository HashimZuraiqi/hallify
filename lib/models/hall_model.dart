import 'package:cloud_firestore/cloud_firestore.dart';

enum HallType { wedding, conference, both }

class HallModel {
  final String id;
  final String organizerId;
  final String organizerName;
  final String name;
  final String description;
  final HallType type;
  final int capacity;
  final double pricePerHour;
  final double pricePerDay;
  final List<String> features;
  final List<String> imageUrls; // DEPRECATED: Use imageBase64
  final List<String> imageBase64; // Base64 encoded images for Firestore
  final String city;
  final String address;
  final GeoPoint? location; // Firestore GeoPoint for location
  final double latitude; // Computed from location or legacy
  final double longitude; // Computed from location or legacy
  final bool isAvailable;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Aliases for consistency
  bool get isActive => isAvailable;
  int get reviewCount => totalReviews;

  HallModel({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.name,
    required this.description,
    required this.type,
    required this.capacity,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.features,
    this.imageUrls = const [],
    this.imageBase64 = const [],
    required this.city,
    required this.address,
    this.location,
    double? latitude,
    double? longitude,
    this.isAvailable = true,
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.createdAt,
    this.updatedAt,
  })  : latitude = latitude ?? location?.latitude ?? 0.0,
        longitude = longitude ?? location?.longitude ?? 0.0;

  /// Create HallModel from Firestore document
  factory HallModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      print('📄 Parsing hall: ${data['name']} (ID: ${doc.id})');
      
      return HallModel(
        id: doc.id,
        organizerId: data['organizerId'] ?? '',
        organizerName: data['organizerName'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        type: HallType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => HallType.both,
        ),
        capacity: data['capacity'] ?? 0,
        pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
        pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
        features: List<String>.from(data['features'] ?? []),
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        imageBase64: List<String>.from(data['imageBase64'] ?? []),
        city: data['city'] ?? '',
        address: data['address'] ?? '',
        location: data['location'] as GeoPoint?,
        latitude: (data['latitude'] ?? 0).toDouble(),
        longitude: (data['longitude'] ?? 0).toDouble(),
        isAvailable: data['isAvailable'] ?? true,
        rating: (data['rating'] ?? 0).toDouble(),
        totalReviews: data['totalReviews'] ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR parsing hall ${doc.id}: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Create HallModel from Map
  factory HallModel.fromMap(Map<String, dynamic> map, String id) {
    return HallModel(
      id: id,
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: HallType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => HallType.both,
      ),
      capacity: map['capacity'] ?? 0,
      pricePerHour: (map['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      features: List<String>.from(map['features'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      imageBase64: List<String>.from(map['imageBase64'] ?? []),
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      location: map['location'] as GeoPoint?,
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert HallModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'organizerName': organizerName,
      'name': name,
      'description': description,
      'type': type.name,
      'capacity': capacity,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'features': features,
      'imageUrls': imageUrls,
      'imageBase64': imageBase64,
      'city': city,
      'address': address,
      if (location != null) 'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'rating': rating,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  HallModel copyWith({
    String? id,
    String? organizerId,
    String? organizerName,
    String? name,
    String? description,
    HallType? type,
    int? capacity,
    double? pricePerHour,
    double? pricePerDay,
    List<String>? features,
    List<String>? imageUrls,
    List<String>? imageBase64,
    String? city,
    String? address,
    GeoPoint? location,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    double? rating,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HallModel(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      features: features ?? this.features,
      imageUrls: imageUrls ?? this.imageUrls,
      imageBase64: imageBase64 ?? this.imageBase64,
      city: city ?? this.city,
      address: address ?? this.address,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get hall type display name
  String get typeDisplayName {
    switch (type) {
      case HallType.wedding:
        return 'Wedding Hall';
      case HallType.conference:
        return 'Conference Hall';
      case HallType.both:
        return 'Wedding & Conference Hall';
    }
  }

  /// Get first image URL or Base64 or placeholder
  String get primaryImageUrl {
    // First check URL images (Cloudinary - fast)
    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }
    // Fallback to Base64 for backward compatibility
    if (imageBase64.isNotEmpty) {
      return imageBase64.first;
    }
    return '';
  }

  /// Check if hall has URL images (Cloudinary)
  bool get hasUrlImages => imageUrls.isNotEmpty;
  
  /// Check if hall has Base64 images (legacy)
  bool get hasBase64Images => imageBase64.isNotEmpty;
  
  /// Get all available images (URLs first, then Base64)
  List<String> get allImages => [...imageUrls, ...imageBase64];

  /// Get formatted price
  String get formattedPricePerHour => '${pricePerHour.toStringAsFixed(0)} JOD/hr';
  String get formattedPricePerDay => '${pricePerDay.toStringAsFixed(0)} JOD/day';

  @override
  String toString() {
    return 'HallModel(id: $id, name: $name, type: $type, city: $city)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HallModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
