import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/hall_model.dart';
import '../models/user_model.dart';
import '../services/booking_service.dart';

/// Provider for managing bookings with real-time updates.
/// Supports both customer and organizer views.
class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  // State
  List<BookingModel> _myBookings = [];
  List<BookingModel> _organizerBookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Stream subscriptions for real-time updates
  StreamSubscription? _myBookingsSubscription;
  StreamSubscription? _organizerBookingsSubscription;

  // Getters
  List<BookingModel> get myBookings => _myBookings;
  List<BookingModel> get organizerBookings => _organizerBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Filtered lists for customers
  List<BookingModel> get upcomingBookings => _myBookings
      .where((b) => b.isConfirmed && b.isUpcoming)
      .toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));

  List<BookingModel> get pastBookings => _myBookings
      .where((b) => b.isPast)
      .toList()
    ..sort((a, b) => b.startAt.compareTo(a.startAt));

  List<BookingModel> get cancelledBookings => _myBookings
      .where((b) => b.isCancelled)
      .toList();

  // Filtered lists for organizers
  List<BookingModel> get upcomingOrganizerBookings => _organizerBookings
      .where((b) => b.isConfirmed && b.isUpcoming)
      .toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));

  List<BookingModel> get todayOrganizerBookings {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _organizerBookings
        .where((b) => 
            b.isConfirmed && 
            b.startAt.isAfter(today) && 
            b.startAt.isBefore(tomorrow))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  // ==================== REAL-TIME STREAMS ====================

  /// Start listening to user's bookings (for customers)
  void startListeningToMyBookings(String userId) {
    _myBookingsSubscription?.cancel();
    _myBookingsSubscription = _bookingService.getUserBookings(userId).listen(
      (bookings) {
        _myBookings = bookings;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load bookings: $error';
        notifyListeners();
      },
    );
  }

  /// Start listening to organizer's bookings
  void startListeningToOrganizerBookings(String organizerId) {
    _organizerBookingsSubscription?.cancel();
    _organizerBookingsSubscription = _bookingService.getOrganizerBookings(organizerId).listen(
      (bookings) {
        _organizerBookings = bookings;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load bookings: $error';
        notifyListeners();
      },
    );
  }

  /// Stop all listeners (call on dispose)
  void stopListening() {
    _myBookingsSubscription?.cancel();
    _organizerBookingsSubscription?.cancel();
    _myBookingsSubscription = null;
    _organizerBookingsSubscription = null;
  }

  // ==================== BOOKING OPERATIONS ====================

  /// Create a new booking
  Future<bool> createBooking({
    required HallModel venue,
    required UserModel user,
    required TimeSlot slot,
    String? notes,
  }) async {
    print('DEBUG BOOKING: Starting createBooking...');
    print('DEBUG BOOKING: venueId=${venue.id}, userId=${user.id}');
    print('DEBUG BOOKING: slot=${slot.startAt} to ${slot.endAt}');
    
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final booking = BookingModel(
        id: '',
        venueId: venue.id,
        venueName: venue.name,
        venueImageUrl: venue.primaryImageUrl,
        organizerId: venue.organizerId,
        organizerName: venue.organizerName,
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userPhone: user.phone ?? '',
        startAt: slot.startAt,
        endAt: slot.endAt,
        status: BookingStatus.confirmed,
        notes: notes,
        createdAt: DateTime.now(),
      );

      print('DEBUG BOOKING: Calling bookingService.createBooking...');
      final bookingId = await _bookingService.createBooking(booking);
      print('DEBUG BOOKING: SUCCESS! Booking created with ID: $bookingId');
      
      _successMessage = 'Booking confirmed!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on BookingConflictException catch (e) {
      print('DEBUG BOOKING: CONFLICT ERROR: ${e.message}');
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('DEBUG BOOKING: ERROR: $e');
      print('DEBUG BOOKING: Stack trace: $stackTrace');
      _errorMessage = 'Failed to create booking: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookingService.cancelBooking(bookingId);
      
      _successMessage = 'Booking cancelled';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel booking: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Edit a booking (change time)
  Future<bool> editBooking({
    required String oldBookingId,
    required HallModel venue,
    required UserModel user,
    required TimeSlot newSlot,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newBooking = BookingModel(
        id: '',
        venueId: venue.id,
        venueName: venue.name,
        venueImageUrl: venue.primaryImageUrl,
        organizerId: venue.organizerId,
        organizerName: venue.organizerName,
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userPhone: user.phone ?? '',
        startAt: newSlot.startAt,
        endAt: newSlot.endAt,
        status: BookingStatus.confirmed,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _bookingService.editBooking(
        oldBookingId: oldBookingId,
        newBooking: newBooking,
      );
      
      _successMessage = 'Booking updated!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on BookingConflictException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update booking: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get a specific booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    return await _bookingService.getBookingById(bookingId);
  }

  // ==================== UTILITY ====================

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
