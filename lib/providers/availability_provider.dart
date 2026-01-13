import 'package:flutter/foundation.dart';
import '../models/availability_slot_model.dart';
import '../services/availability_service.dart';

class AvailabilityProvider with ChangeNotifier {
  final AvailabilityService _service = AvailabilityService();

  List<AvailabilitySlotModel> _slots = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AvailabilitySlotModel> get slots => _slots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get available slots only
  List<AvailabilitySlotModel> get availableSlots =>
      _slots.where((s) => s.isAvailable).toList();

  /// Get booked slots only
  List<AvailabilitySlotModel> get bookedSlots =>
      _slots.where((s) => !s.isAvailable && s.bookedBy != null).toList();

  /// Generate slots for date range
  Future<void> generateSlots({
    required String hallId,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime,
    required String endTime,
    required int slotDuration,
    List<int> excludedWeekdays = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.generateSlotsForDateRange(
        hallId: hallId,
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        slotDuration: slotDuration,
        excludedWeekdays: excludedWeekdays,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load available slots for a specific date
  Future<void> loadAvailableSlotsForDate({
    required String hallId,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _slots = await _service.getAvailableSlotsForDate(
        hallId: hallId,
        date: date,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all slots (available and booked) for a date
  Future<void> loadAllSlotsForDate({
    required String hallId,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _slots = await _service.getAllSlotsForDate(
        hallId: hallId,
        date: date,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle slot availability
  Future<void> toggleSlotAvailability(String slotId, bool isAvailable) async {
    try {
      await _service.toggleSlotAvailability(slotId, isAvailable);

      // Update local list
      final index = _slots.indexWhere((s) => s.id == slotId);
      if (index != -1) {
        _slots[index] = _slots[index].copyWith(isAvailable: isAvailable);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Block entire day
  Future<void> blockDay(String hallId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.blockDay(hallId, date);
      
      // Reload slots to reflect changes
      await loadAllSlotsForDate(hallId: hallId, date: date);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Unblock entire day
  Future<void> unblockDay(String hallId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.unblockDay(hallId, date);
      
      // Reload slots to reflect changes
      await loadAllSlotsForDate(hallId: hallId, date: date);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Free slot by visit ID (when visit cancelled/rejected)
  Future<void> freeSlotByVisitId(String visitId) async {
    try {
      await _service.freeSlotByVisitId(visitId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete all slots for a hall
  Future<void> deleteAllSlotsForHall(String hallId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteAllSlotsForHall(hallId);
      _slots = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
