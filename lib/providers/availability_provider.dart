import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/availability_rule_model.dart';
import '../models/booking_model.dart';
import '../services/availability_service.dart';

/// Provider for managing availability rules and generating time slots.
/// Slots are generated at runtime - never stored in the database.
class AvailabilityProvider with ChangeNotifier {
  final AvailabilityService _availabilityService = AvailabilityService();

  // State
  List<AvailabilityRuleModel> _rules = [];
  List<TimeSlot> _availableSlots = [];
  Map<DateTime, bool> _dateAvailability = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscription
  StreamSubscription? _rulesSubscription;

  // Getters
  List<AvailabilityRuleModel> get rules => _rules;
  List<TimeSlot> get availableSlots => _availableSlots;
  Map<DateTime, bool> get dateAvailability => _dateAvailability;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filtered rules
  List<AvailabilityRuleModel> get weeklyRules => 
      _rules.where((r) => r.type == RuleType.weekly).toList()
        ..sort((a, b) => (a.weekday ?? 0).compareTo(b.weekday ?? 0));

  List<AvailabilityRuleModel> get specificDateRules => 
      _rules.where((r) => r.type == RuleType.specificDate).toList()
        ..sort((a, b) => (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

  List<AvailabilityRuleModel> get blockedDates => 
      _rules.where((r) => r.isBlocked).toList();

  // ==================== REAL-TIME RULES STREAM ====================

  /// Start listening to venue rules
  void startListeningToRules(String venueId) {
    _rulesSubscription?.cancel();
    _rulesSubscription = _availabilityService.getVenueRulesStream(venueId).listen(
      (rules) {
        _rules = rules;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load rules: $error';
        notifyListeners();
      },
    );
  }

  /// Stop listening
  void stopListening() {
    _rulesSubscription?.cancel();
    _rulesSubscription = null;
  }

  // ==================== SLOT GENERATION ====================

  /// Load available slots for a specific date
  Future<void> loadAvailableSlots({
    required String venueId,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableSlots = await _availabilityService.generateAvailableSlots(
        venueId: venueId,
        date: date,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load slots: $e';
      _availableSlots = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all slots (with availability status) for a specific date
  Future<void> loadAllSlots({
    required String venueId,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableSlots = await _availabilityService.generateAllSlots(
        venueId: venueId,
        date: date,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load slots: $e';
      _availableSlots = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load date availability for calendar display
  Future<void> loadDateAvailability({
    required String venueId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _dateAvailability = await _availabilityService.getAvailabilityForDateRange(
        venueId: venueId,
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load availability: $e';
      notifyListeners();
    }
  }

  /// Check if a specific date has available slots
  bool isDateAvailable(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _dateAvailability[key] ?? false;
  }

  // ==================== RULE MANAGEMENT (FOR ORGANIZERS) ====================

  /// Load rules for a venue (one-time, non-streaming)
  Future<void> loadRules(String venueId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rules = await _availabilityService.getVenueRules(venueId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load rules: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new weekly rule (replaces existing rule for same weekday)
  Future<bool> createWeeklyRule({
    required String venueId,
    required int weekday,
    required String startTime,
    required String endTime,
    int slotDuration = 60,
    int buffer = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if a rule already exists for this weekday and delete it
      final existingRule = _rules.firstWhere(
        (r) => r.type == RuleType.weekly && r.weekday == weekday,
        orElse: () => AvailabilityRuleModel(
          id: '',
          venueId: venueId,
          type: RuleType.weekly,
          startTime: '',
          endTime: '',
          createdAt: DateTime.now(),
        ),
      );
      
      if (existingRule.id.isNotEmpty) {
        // Delete existing rule first
        await _availabilityService.deleteRule(existingRule.id);
      }

      final rule = AvailabilityRuleModel(
        id: '',
        venueId: venueId,
        type: RuleType.weekly,
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
        slotDurationMinutes: slotDuration,
        bufferMinutes: buffer,
        createdAt: DateTime.now(),
      );

      await _availabilityService.createRule(rule);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create rule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a specific date rule (override or block)
  Future<bool> createSpecificDateRule({
    required String venueId,
    required DateTime date,
    required String startTime,
    required String endTime,
    int slotDuration = 60,
    int buffer = 0,
    bool isBlocked = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rule = AvailabilityRuleModel(
        id: '',
        venueId: venueId,
        type: RuleType.specificDate,
        date: date,
        startTime: startTime,
        endTime: endTime,
        slotDurationMinutes: slotDuration,
        bufferMinutes: buffer,
        isBlocked: isBlocked,
        createdAt: DateTime.now(),
      );

      await _availabilityService.createRule(rule);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create rule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Block a specific date
  Future<bool> blockDate({
    required String venueId,
    required DateTime date,
  }) async {
    return await createSpecificDateRule(
      venueId: venueId,
      date: date,
      startTime: '00:00',
      endTime: '00:00',
      isBlocked: true,
    );
  }

  /// Update an existing rule
  Future<bool> updateRule(AvailabilityRuleModel rule) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _availabilityService.updateRule(rule);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update rule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a rule
  Future<bool> deleteRule(String ruleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _availabilityService.deleteRule(ruleId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete rule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create default weekly rules (Mon-Fri, 9am-6pm)
  Future<bool> createDefaultRules({
    required String venueId,
    String startTime = '09:00',
    String endTime = '18:00',
    int slotDuration = 60,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _availabilityService.createDefaultWeeklyRules(
        venueId: venueId,
        startTime: startTime,
        endTime: endTime,
        slotDuration: slotDuration,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create rules: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== UTILITY ====================

  /// Clear slots
  void clearSlots() {
    _availableSlots = [];
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
