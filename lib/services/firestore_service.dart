import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hall_model.dart';
import '../models/visit_request_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/availability_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _hallsCollection => _firestore.collection('halls');
  CollectionReference get _visitsCollection => _firestore.collection('visitRequests');
  CollectionReference get _conversationsCollection => _firestore.collection('conversations');
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  
  // Services
  final AvailabilityService _availabilityService = AvailabilityService();

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
    print('📡 Firestore query: halls where isAvailable=true');
    return _hallsCollection
        .where('isAvailable', isEqualTo: true)
        // .orderBy('createdAt', descending: true)  // TEMPORARILY DISABLED - needs index
        .snapshots()
        .map((snapshot) {
          print('📦 Firestore returned ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) => HallModel.fromFirestore(doc)).toList();
        });
  }

  /// Get halls by organizer ID
  Stream<List<HallModel>> getHallsByOrganizer(String organizerId) {
    return _hallsCollection
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HallModel.fromFirestore(doc)).toList());
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
      List<HallModel> halls = snapshot.docs.map((doc) => HallModel.fromFirestore(doc)).toList();

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

      return snapshot.docs.map((doc) => HallModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get featured halls: $e');
    }
  }

  // ==================== VISIT REQUEST OPERATIONS ====================

  /// Create a visit request with transaction to prevent double booking (FREE)
  /// Also enforces ONE pending/approved request per user per hall
  Future<String> createVisitRequest(VisitRequestModel visit) async {
    try {
      // Use Firestore transaction to prevent race conditions
      final String? visitId = await _firestore.runTransaction<String?>((transaction) async {
        // 1. Check if THIS USER already has a pending/approved request for this hall
        final userExistingSnapshot = await _visitsCollection
            .where('hallId', isEqualTo: visit.hallId)
            .where('customerId', isEqualTo: visit.customerId)
            .where('status', whereIn: ['pending', 'approved']).get();

        if (userExistingSnapshot.docs.isNotEmpty) {
          final existing = VisitRequestModel.fromFirestore(userExistingSnapshot.docs.first);
          throw Exception(
            'You already have a booking for this hall on ${_formatDate(existing.visitDate)} at ${existing.visitTime}. '
            'Please wait for approval or cancel your existing request.'
          );
        }

        // 2. Check if ANY OTHER USER has booked the same time slot
        final timeSlotSnapshot = await _visitsCollection
            .where('hallId', isEqualTo: visit.hallId)
            .where('visitDate', isEqualTo: Timestamp.fromDate(visit.visitDate))
            .where('status', whereIn: ['pending', 'approved']).get();

        // Check for time slot overlap
        for (var doc in timeSlotSnapshot.docs) {
          final existing = VisitRequestModel.fromFirestore(doc);
          if (existing.visitTime == visit.visitTime) {
            throw Exception('This time slot is already booked by another user');
          }
        }

        // 3. No conflict - create visit request
        final newDocRef = _visitsCollection.doc();
        transaction.set(newDocRef, visit.toMap());
        return newDocRef.id;
      });

      if (visitId == null) {
        throw Exception('Failed to create visit request');
      }

      return visitId;
    } catch (e) {
      throw Exception('${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Helper to format date for error messages
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
        .map((snapshot) => snapshot.docs.map((doc) => VisitRequestModel.fromFirestore(doc)).toList());
  }

  /// Get visit requests for organizer
  Stream<List<VisitRequestModel>> getOrganizerVisitRequests(String organizerId) {
    return _visitsCollection
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VisitRequestModel.fromFirestore(doc)).toList());
  }

  /// Get visit requests for a specific hall
  Stream<List<VisitRequestModel>> getHallVisitRequests(String hallId) {
    return _visitsCollection
        .where('hallId', isEqualTo: hallId)
        .orderBy('visitDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VisitRequestModel.fromFirestore(doc)).toList());
  }



  /// Get user's existing pending or approved visit for a specific hall
  Future<VisitRequestModel?> getUserPendingVisitForHall({
    required String hallId,
    required String customerId,
  }) async {
    try {
      final snapshot = await _visitsCollection
          .where('hallId', isEqualTo: hallId)
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return VisitRequestModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
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
          .where('status', whereIn: ['pending', 'approved']).get();

      return snapshot.docs.map((doc) => VisitRequestModel.fromFirestore(doc).visitTime).toList();
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
      final snapshot = await _conversationsCollection.where('participants', arrayContains: userId1).get();

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
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  /// Get conversations for a user
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _conversationsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ConversationModel.fromFirestore(doc)).toList());
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

  // ==================== HALL SLOT LOCKING (RACE-CONDITION SAFE) ====================

  /// Check if a time slot is available (checking both hallSlots and visitRequests)
  Future<bool> isTimeSlotAvailable({
    required String hallId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final dateStr = _formatDate(date);
      final timeStr = time.split('-')[0].trim();
      
      // 1. Check atomic hallSlots (Single Source of Truth)
      final slotId = '${hallId}_${dateStr}_$timeStr';
      final slotDoc = await _firestore.collection('hallSlots').doc(slotId).get();
      if (slotDoc.exists) return false; // Already locked

      // 2. Check overlap in visitRequests (Double-Check)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final query = await _visitsCollection
          .where('hallId', isEqualTo: hallId)
          .where('visitDate', isEqualTo: Timestamp.fromDate(startOfDay))
          .where('visitTime', isEqualTo: time)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      return false; // Assume unavailable on error safety
    }
  }

  /// Approve visit and lock slot atomically (prevents race conditions)
  Future<void> approveVisitAndLockSlot(VisitRequestModel visit) async {
    final dateStr = _formatDate(visit.visitDate);
    final timeStr = visit.visitTime.split('-')[0].trim(); // Get start time
    final slotId = '${visit.hallId}_${dateStr}_$timeStr';
    
    final slotRef = _firestore.collection('hallSlots').doc(slotId);
    final visitRef = _visitsCollection.doc(visit.id);

    await _firestore.runTransaction((transaction) async {
      // 1. Check if slot already exists (atomic check)
      final slotDoc = await transaction.get(slotRef);
      if (slotDoc.exists) {
        throw Exception('This time slot is already booked by another user');
      }

      // 2. Create slot lock atomically
      transaction.set(slotRef, {
        'hallId': visit.hallId,
        'date': dateStr,
        'time': timeStr,
        'booked': true,
        'visitId': visit.id,
        'organizerId': visit.organizerId,
        'customerId': visit.customerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update visit status
      transaction.update(visitRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Free slot when visit is cancelled or rejected (delete slot document)
  Future<void> freeSlotByVisitId(String visitId) async {
    // Find slot with this visitId and delete it
    final snapshot = await _firestore
        .collection('hallSlots')
        .where('visitId', isEqualTo: visitId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  /// Get booked slots for a hall and date
  Future<List<String>> getBookedTimesForDate({
    required String hallId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final snapshot = await _firestore
        .collection('hallSlots')
        .where('hallId', isEqualTo: hallId)
        .where('date', isEqualTo: dateStr)
        .where('booked', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['time'] as String?) ?? '')
        .where((time) => time.isNotEmpty)
        .toList();
  }
}
