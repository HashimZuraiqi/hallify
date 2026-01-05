import 'package:flutter/foundation.dart';
import '../models/visit_request_model.dart';
import '../services/firestore_service.dart';

class VisitProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<VisitRequestModel> _customerVisits = [];
  List<VisitRequestModel> _organizerVisits = [];
  List<String> _bookedTimeSlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<VisitRequestModel> get customerVisits => _customerVisits;
  List<VisitRequestModel> get organizerVisits => _organizerVisits;
  List<String> get bookedTimeSlots => _bookedTimeSlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered lists
  List<VisitRequestModel> get pendingOrganizerVisits => _organizerVisits.where((v) => v.isPending).toList();
  List<VisitRequestModel> get approvedOrganizerVisits => _organizerVisits.where((v) => v.isApproved).toList();
  List<VisitRequestModel> get rejectedOrganizerVisits => _organizerVisits.where((v) => v.isRejected).toList();

  List<VisitRequestModel> get pendingCustomerVisits => _customerVisits.where((v) => v.isPending).toList();
  List<VisitRequestModel> get approvedCustomerVisits => _customerVisits.where((v) => v.isApproved).toList();
  List<VisitRequestModel> get completedCustomerVisits => _customerVisits.where((v) => v.isCompleted).toList();

  /// Load booked time slots for a hall on a specific date
  Future<void> loadBookedTimeSlots(String hallId, DateTime date) async {
    try {
      _bookedTimeSlots = await _firestoreService.getBookedTimeSlots(hallId, date);
      notifyListeners();
    } catch (e) {
      _bookedTimeSlots = [];
      notifyListeners();
    }
  }

  /// Check if a time slot is available
  Future<bool> isTimeSlotAvailable({
    required String hallId,
    required DateTime date,
    required String time,
  }) async {
    return await _firestoreService.isTimeSlotAvailable(
      hallId: hallId,
      date: date,
      time: time,
    );
  }

  /// Mark visit as completed
  Future<bool> completeVisit(String visitId) async {
    try {
      await _firestoreService.updateVisitStatus(
        visitId: visitId,
        status: VisitStatus.completed,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Complete visit request (alias)
  Future<void> completeVisitRequest(String visitId) async {
    await completeVisit(visitId);
  }

  /// Approve visit request (with String visitId parameter)
  Future<void> approveVisitRequest(String visitId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateVisitStatus(
        visitId: visitId,
        status: VisitStatus.approved,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Reject visit request (with String visitId and reason)
  Future<void> rejectVisitRequest(String visitId, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.updateVisitStatus(
        visitId: visitId,
        status: VisitStatus.rejected,
        rejectionReason: reason,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel a visit request
  Future<bool> cancelVisitRequest(String visitId) async {
    try {
      await _firestoreService.updateVisitStatus(
        visitId: visitId,
        status: VisitStatus.cancelled,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Create visit request (accepts VisitRequestModel)
  Future<void> createVisitRequest(VisitRequestModel visitRequest) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.createVisitRequest(visitRequest);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Check time slot conflict
  Future<bool> checkTimeSlotConflict({
    required String hallId,
    required DateTime date,
    required String timeSlot,
  }) async {
    // Return true only when there is a conflict (slot already taken)
    final isAvailable = await _firestoreService.isTimeSlotAvailable(
      hallId: hallId,
      date: date,
      time: timeSlot,
    );
    return !isAvailable;
  }

  /// Load customer visits (void return - updates provider state)
  Future<void> loadCustomerVisits(String customerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the stream-based method that exists in FirestoreService
      _firestoreService.getCustomerVisitRequests(customerId).listen(
        (visits) {
          _customerVisits = visits;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
      // Ensure loading state clears even if no snapshots are emitted immediately
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load organizer visits (void return - updates provider state)
  Future<void> loadOrganizerVisits(String organizerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the stream-based method that exists in FirestoreService
      _firestoreService.getOrganizerVisitRequests(organizerId).listen(
        (visits) {
          _organizerVisits = visits;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
