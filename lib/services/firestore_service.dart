import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hall_model.dart';
import '../models/visit_request_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _hallsCollection => _firestore.collection('halls');
  CollectionReference get _visitsCollection => _firestore.collection('visitRequests');
  CollectionReference get _conversationsCollection => _firestore.collection('conversations');
  CollectionReference get _messagesCollection => _firestore.collection('messages');

  // ==================== HALL OPERATIONS ====================

  /// Create a new hall
  Future<String> createHall(HallModel hall) async {
    try {
      final docRef = await _hallsCollection.add(hall.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create hall: $e');
    }
  }

  /// Update an existing hall
  Future<void> updateHall(HallModel hall) async {
    try {
      await _hallsCollection.doc(hall.id).update({
        ...hall.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update hall: $e');
    }
  }

  /// Delete a hall
  Future<void> deleteHall(String hallId) async {
    try {
      await _hallsCollection.doc(hallId).delete();
    } catch (e) {
      throw Exception('Failed to delete hall: $e');
    }
  }

  /// Get hall by ID
  Future<HallModel?> getHallById(String hallId) async {
    try {
      final doc = await _hallsCollection.doc(hallId).get();
      if (!doc.exists) return null;
      return HallModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get hall: $e');
    }
  }

  /// Get all halls (for customers)
  Stream<List<HallModel>> getAllHalls() {
    return _hallsCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HallModel.fromFirestore(doc))
            .toList());
  }

  /// Get halls by organizer ID
  Stream<List<HallModel>> getHallsByOrganizer(String organizerId) {
    return _hallsCollection
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HallModel.fromFirestore(doc))
            .toList());
  }

  /// Search halls with filters
  Future<List<HallModel>> searchHalls({
    String? city,
    HallType? type,
    int? minCapacity,
    int? maxCapacity,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      Query query = _hallsCollection.where('isAvailable', isEqualTo: true);

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.get();
      List<HallModel> halls = snapshot.docs
          .map((doc) => HallModel.fromFirestore(doc))
          .toList();

      // Apply additional filters in memory
      if (minCapacity != null) {
        halls = halls.where((h) => h.capacity >= minCapacity).toList();
      }
      if (maxCapacity != null) {
        halls = halls.where((h) => h.capacity <= maxCapacity).toList();
      }
      if (minPrice != null) {
        halls = halls.where((h) => h.pricePerHour >= minPrice).toList();
      }
      if (maxPrice != null) {
        halls = halls.where((h) => h.pricePerHour <= maxPrice).toList();
      }

      return halls;
    } catch (e) {
      throw Exception('Failed to search halls: $e');
    }
  }

  /// Get featured halls
  Future<List<HallModel>> getFeaturedHalls({int limit = 5}) async {
    try {
      final snapshot = await _hallsCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => HallModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get featured halls: $e');
    }
  }

  // ==================== VISIT REQUEST OPERATIONS ====================

  /// Create a visit request
  Future<String> createVisitRequest(VisitRequestModel visit) async {
    try {
      // Check if time slot is available
      final isAvailable = await isTimeSlotAvailable(
        hallId: visit.hallId,
        date: visit.visitDate,
        time: visit.visitTime,
      );

      if (!isAvailable) {
        throw Exception('This time slot is not available');
      }

      final docRef = await _visitsCollection.add(visit.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create visit request: $e');
    }
  }

  /// Update visit request status
  Future<void> updateVisitStatus({
    required String visitId,
    required VisitStatus status,
    String? rejectionReason,
  }) async {
    try {
      final updates = {
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      if (rejectionReason != null) {
        updates['rejectionReason'] = rejectionReason;
      }

      await _visitsCollection.doc(visitId).update(updates);
    } catch (e) {
      throw Exception('Failed to update visit status: $e');
    }
  }

  /// Get visit requests for customer
  Stream<List<VisitRequestModel>> getCustomerVisitRequests(String customerId) {
    return _visitsCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Get visit requests for organizer
  Stream<List<VisitRequestModel>> getOrganizerVisitRequests(String organizerId) {
    return _visitsCollection
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Get visit requests for a specific hall
  Stream<List<VisitRequestModel>> getHallVisitRequests(String hallId) {
    return _visitsCollection
        .where('hallId', isEqualTo: hallId)
        .orderBy('visitDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VisitRequestModel.fromFirestore(doc))
            .toList());
  }

  /// Check if time slot is available
  Future<bool> isTimeSlotAvailable({
    required String hallId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _visitsCollection
          .where('hallId', isEqualTo: hallId)
          .where('visitDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('visitDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      // Check if any existing visit conflicts with the requested time
      for (var doc in snapshot.docs) {
        final visit = VisitRequestModel.fromFirestore(doc);
        if (visit.visitTime == time) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return true; // Allow booking if check fails
    }
  }

  /// Get booked time slots for a hall on a specific date
  Future<List<String>> getBookedTimeSlots(String hallId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _visitsCollection
          .where('hallId', isEqualTo: hallId)
          .where('visitDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('visitDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      return snapshot.docs
          .map((doc) => VisitRequestModel.fromFirestore(doc).visitTime)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== MESSAGING OPERATIONS ====================

  /// Get or create conversation
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userName1,
    required String userId2,
    required String userName2,
    String? hallId,
    String? hallName,
  }) async {
    try {
      // Check if conversation exists
      final snapshot = await _conversationsCollection
          .where('participants', arrayContains: userId1)
          .get();

      for (var doc in snapshot.docs) {
        final conversation = ConversationModel.fromFirestore(doc);
        if (conversation.participants.contains(userId2)) {
          return doc.id;
        }
      }

      // Create new conversation
      final conversation = ConversationModel(
        id: '',
        participants: [userId1, userId2],
        lastMessage: '',
        lastSenderId: '',
        lastMessageTime: DateTime.now(),
        unreadCount: {userId1: 0, userId2: 0},
        participantNames: {userId1: userName1, userId2: userName2},
        hallId: hallId,
        hallName: hallName,
      );

      final docRef = await _conversationsCollection.add(conversation.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage(MessageModel message) async {
    try {
      // Add message to messages collection
      await _messagesCollection.add(message.toMap());

      // Update conversation
      await _conversationsCollection.doc(message.conversationId).update({
        'lastMessage': message.content,
        'lastSenderId': message.senderId,
        'lastMessageTime': Timestamp.fromDate(message.createdAt),
        'unreadCount.${message.receiverId}': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages for a conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Get conversations for a user
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _conversationsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Update unread count in conversation
      await _conversationsCollection.doc(conversationId).update({
        'unreadCount.$userId': 0,
      });

      // Mark individual messages as read
      final snapshot = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // Silently fail
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Get FCM token for a user
  Future<String?> getUserFcmToken(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return (doc.data() as Map<String, dynamic>)['fcmToken'];
    } catch (e) {
      return null;
    }
  }
}
