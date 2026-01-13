import 'package:flutter/foundation.dart';
import '../models/visit_request_model.dart';
import '../services/firestore_service.dart';
import '../services/in_app_notification_service.dart';

class VisitProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final InAppNotificationService _notificationService = InAppNotificationService();

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
      // Get the visit first to send notification
      final visit = _organizerVisits.firstWhere((v) => v.id == visitId,
        orElse: () => _customerVisits.firstWhere((v) => v.id == visitId));
      
      await _firestoreService.updateVisitStatus(
        visitId: visitId,
        status: VisitStatus.completed,
      );
      
      // Send completion notification to customer (optional, nice touch)
      try {
        await _notificationService.sendVisitCompletedNotification(
          customerId: visit.customerId,
          hallName: visit.hallName,
          visitId: visit.id,
          hallId: visit.hallId,
        );
      } catch (e) {
        print('Warning: Failed to send completion notification: $e');
      }
      
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
      // Get the visit request first
      final visit = _organizerVisits.firstWhere((v) => v.id == visitId);
      
      // Use transaction to approve and lock slot
      await _firestoreService.approveVisitAndLockSlot(visit);
      
      // Send approval notification to customer (in-app, no FCM needed)
      await _notificationService.sendTimeSlotApprovalNotification(
        customerFcmToken: visit.customerId, // Now treated as userId
        hallName: visit.hallName,
        visitDate: '${visit.visitDate.year}-${visit.visitDate.month}-${visit.visitDate.day}',
        visitTime: visit.visitTime,
        visitId: visit.id,
        hallId: visit.hallId,
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
      // Get the visit request first to send notification
      final visit = _organizerVisits.firstWhere((v) => v.id == visitId);
      
      await _firestoreService.updateVisitStatus(
        visitId: visitId,
        status: VisitStatus.rejected,
        rejectionReason: reason,
      );
      
      // Send rejection notification to customer (in-app, no FCM needed)
      await _notificationService.sendTimeSlotRejectionNotification(
        customerFcmToken: visit.customerId, // Now treated as userId
        hallName: visit.hallName,
        reason: reason ?? 'No reason provided',
        visitId: visit.id,
        hallId: visit.hallId,
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
      
      // Free the availability slot if it was approved/booked
      await _firestoreService.freeSlotByVisitId(visitId);
      
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
      final visitId = await _firestoreService.createVisitRequest(visitRequest);
      
      // Send notification to organizer (in-app, no FCM needed)
      await _notificationService.sendTimeSlotRequestNotification(
        organizerFcmToken: visitRequest.organizerId, // Now treated as userId
        customerName: visitRequest.customerName,
        hallName: visitRequest.hallName,
        visitDate: '${visitRequest.visitDate.year}-${visitRequest.visitDate.month}-${visitRequest.visitDate.day}',
        visitTime: visitRequest.visitTime,
        visitId: visitId,
        hallId: visitRequest.hallId,
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
