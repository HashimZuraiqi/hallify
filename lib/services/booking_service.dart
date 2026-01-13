import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

/// Enterprise-grade booking service with conflict prevention.
/// Uses Firestore to prevent double-booking.
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _chatRoomsCollection => _firestore.collection('chat_rooms');

  /// Create a booking with conflict prevention.
  /// Checks for overlapping bookings before creating.
  /// Returns the booking ID if successful, throws exception if conflict exists.
  Future<String> createBooking(BookingModel booking) async {
    print('DEBUG SERVICE: Starting createBooking...');
    
    try {
      // 1. Check for conflicts BEFORE transaction (transactions can't do queries)
      print('DEBUG SERVICE: Checking for conflicts...');
      final potentialConflicts = await _bookingsCollection
          .where('venueId', isEqualTo: booking.venueId)
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .where('startAt', isLessThan: Timestamp.fromDate(booking.endAt))
          .get();

      print('DEBUG SERVICE: Found ${potentialConflicts.docs.length} potential conflicts');

      // Check for actual overlaps
      for (final doc in potentialConflicts.docs) {
        final existing = BookingModel.fromFirestore(doc);
        if (existing.endAt.isAfter(booking.startAt)) {
          print('DEBUG SERVICE: CONFLICT with booking ${doc.id}');
          throw BookingConflictException(
            'This time slot is already booked. Please choose another time.',
            existingBooking: existing,
          );
        }
      }

      print('DEBUG SERVICE: No conflicts found, creating booking...');

      // 2. Create booking document
      final bookingRef = _bookingsCollection.doc();
      final chatRoomRef = _chatRoomsCollection.doc(bookingRef.id);

      // 3. Prepare booking with IDs
      final bookingWithIds = booking.copyWith(
        id: bookingRef.id,
        chatRoomId: chatRoomRef.id,
      );

      print('DEBUG SERVICE: Creating booking with ID: ${bookingRef.id}');
      
      // 4. Create chat room data
      final chatRoomData = {
        'bookingId': bookingRef.id,
        'venueId': booking.venueId,
        'venueName': booking.venueName,
        'participants': [booking.userId, booking.organizerId],
        'participantNames': {
          booking.userId: booking.userName,
          booking.organizerId: booking.organizerName,
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          booking.userId: 0,
          booking.organizerId: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 5. Use batch write for atomicity (not transaction - simpler and sufficient)
      final batch = _firestore.batch();
      batch.set(bookingRef, bookingWithIds.toMap());
      batch.set(chatRoomRef, chatRoomData);
      
      print('DEBUG SERVICE: Committing batch write...');
      await batch.commit();
      
      print('DEBUG SERVICE: SUCCESS! Booking created: ${bookingRef.id}');
      return bookingRef.id;
      
    } catch (e) {
      print('DEBUG SERVICE: ERROR: $e');
      rethrow;
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    await _bookingsCollection.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Edit a booking (cancel old, create new)
  Future<String> editBooking({
    required String oldBookingId,
    required BookingModel newBooking,
  }) async {
    // Get old booking to preserve chat room
    final oldBookingDoc = await _bookingsCollection.doc(oldBookingId).get();
    if (!oldBookingDoc.exists) {
      throw Exception('Original booking not found');
    }
    
    final oldBooking = BookingModel.fromFirestore(oldBookingDoc);

    // Check for conflicts with new time (excluding old booking)
    final potentialConflicts = await _bookingsCollection
        .where('venueId', isEqualTo: newBooking.venueId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where('startAt', isLessThan: Timestamp.fromDate(newBooking.endAt))
        .get();

    for (final doc in potentialConflicts.docs) {
      if (doc.id == oldBookingId) continue;
      final existing = BookingModel.fromFirestore(doc);
      if (existing.endAt.isAfter(newBooking.startAt)) {
        throw BookingConflictException(
          'This time slot is already booked. Please choose another time.',
          existingBooking: existing,
        );
      }
    }

    // Cancel old and create new in a batch
    final newBookingRef = _bookingsCollection.doc();
    final bookingWithChatRoom = newBooking.copyWith(
      id: newBookingRef.id,
      chatRoomId: oldBooking.chatRoomId,
    );

    final batch = _firestore.batch();
    
    // Cancel old booking
    batch.update(_bookingsCollection.doc(oldBookingId), {
      'status': BookingStatus.cancelled.name,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Create new booking
    batch.set(newBookingRef, bookingWithChatRoom.toMap());
    
    // Update chat room reference
    if (oldBooking.chatRoomId != null) {
      batch.update(_chatRoomsCollection.doc(oldBooking.chatRoomId), {
        'bookingId': newBookingRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return newBookingRef.id;
  }

  /// Get real-time stream of user's bookings
  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _bookingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  /// Get real-time stream of organizer's bookings
  Stream<List<BookingModel>> getOrganizerBookings(String organizerId) {
    return _bookingsCollection
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  /// Get real-time stream of venue's bookings
  Stream<List<BookingModel>> getVenueBookings(String venueId) {
    return _bookingsCollection
        .where('venueId', isEqualTo: venueId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }

  /// Get confirmed bookings for a venue on a specific date range
  Future<List<BookingModel>> getBookingsForDateRange({
    required String venueId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _bookingsCollection
        .where('venueId', isEqualTo: venueId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('startAt', isLessThan: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();
  }

  /// Get a single booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _bookingsCollection.doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Get booking stream by ID
  Stream<BookingModel?> getBookingStream(String bookingId) {
    return _bookingsCollection
        .doc(bookingId)
        .snapshots()
        .map((doc) => doc.exists ? BookingModel.fromFirestore(doc) : null);
  }
}

/// Custom exception for booking conflicts
class BookingConflictException implements Exception {
  final String message;
  final BookingModel? existingBooking;

  BookingConflictException(this.message, {this.existingBooking});

  @override
  String toString() => message;
}
