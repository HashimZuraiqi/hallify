import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/availability_rule_model.dart';
import '../models/booking_model.dart';

/// Availability service that generates slots at runtime from rules.
/// Slots are NEVER stored in the database - only availability rules are stored.
class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _rulesCollection => _firestore.collection('availability_rules');
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');

  // ==================== AVAILABILITY RULES CRUD ====================

  /// Create a new availability rule
  Future<String> createRule(AvailabilityRuleModel rule) async {
    final docRef = await _rulesCollection.add(rule.toMap());
    return docRef.id;
  }

  /// Update an existing rule
  Future<void> updateRule(AvailabilityRuleModel rule) async {
    await _rulesCollection.doc(rule.id).update({
      ...rule.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a rule
  Future<void> deleteRule(String ruleId) async {
    await _rulesCollection.doc(ruleId).delete();
  }

  /// Get all rules for a venue
  Future<List<AvailabilityRuleModel>> getVenueRules(String venueId) async {
    // DEBUG: First check ALL rules to see what exists
    final allRulesSnapshot = await _rulesCollection.get();
    print('DEBUG: Total rules in database: ${allRulesSnapshot.docs.length}');
    for (final doc in allRulesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      print('DEBUG: Rule ${doc.id} - venueId: ${data['venueId']}, weekday: ${data['weekday']}, type: ${data['type']}');
    }
    
    // Now query for this specific venue
    print('DEBUG: Querying rules for venueId: $venueId');
    final snapshot = await _rulesCollection
        .where('venueId', isEqualTo: venueId)
        .get();
    print('DEBUG: Found ${snapshot.docs.length} rules for this venue');
    
    return snapshot.docs
        .map((doc) => AvailabilityRuleModel.fromFirestore(doc))
        .toList();
  }

  /// Stream of rules for a venue
  Stream<List<AvailabilityRuleModel>> getVenueRulesStream(String venueId) {
    return _rulesCollection
        .where('venueId', isEqualTo: venueId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AvailabilityRuleModel.fromFirestore(doc))
            .toList());
  }

  // ==================== SLOT GENERATION (RUNTIME ONLY) ====================

  /// Generate available time slots for a specific date.
  /// This is the core function - slots are generated at runtime, never stored.
  Future<List<TimeSlot>> generateAvailableSlots({
    required String venueId,
    required DateTime date,
  }) async {
    // 1. Get venue rules
    final rules = await getVenueRules(venueId);
    print('DEBUG: Found ${rules.length} rules for venue $venueId');
    for (final r in rules) {
      print('DEBUG: Rule type=${r.type}, weekday=${r.weekday}, startTime=${r.startTime}');
    }
    
    if (rules.isEmpty) {
      print('DEBUG: No rules found, returning empty slots');
      return [];
    }

    // 2. Find applicable rule for this date
    final applicableRule = _findApplicableRule(rules, date);
    print('DEBUG: Looking for rule for weekday=${date.weekday} (${_weekdayName(date.weekday)})');
    print('DEBUG: Applicable rule found: ${applicableRule != null}');
    
    if (applicableRule == null || applicableRule.isBlocked) {
      print('DEBUG: No applicable rule or day is blocked');
      return [];
    }

    // 3. Generate all possible slots from rule
    final allSlots = _generateSlotsFromRule(applicableRule, date);
    print('DEBUG: Generated ${allSlots.length} slots from rule');

    // 4. Get existing bookings for this date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final bookingsSnapshot = await _bookingsCollection
        .where('venueId', isEqualTo: venueId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final existingBookings = bookingsSnapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();

    // 5. Filter out slots that overlap with existing bookings
    final availableSlots = <TimeSlot>[];
    for (final slot in allSlots) {
      bool hasConflict = false;
      for (final booking in existingBookings) {
        if (slot.overlapsWithBooking(booking)) {
          hasConflict = true;
          break;
        }
      }
      if (!hasConflict) {
        availableSlots.add(slot);
      }
    }

    // 6. Filter out past slots if date is today
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return availableSlots
          .where((slot) => slot.startAt.isAfter(now))
          .toList();
    }

    print('DEBUG: Returning ${availableSlots.length} available slots');
    return availableSlots;
  }

  String _weekdayName(int weekday) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekday >= 1 && weekday <= 7 ? names[weekday] : 'Unknown';
  }

  /// Generate slots with availability status (for calendar display)
  Future<List<TimeSlot>> generateAllSlots({
    required String venueId,
    required DateTime date,
  }) async {
    // 1. Get venue rules
    final rules = await getVenueRules(venueId);
    if (rules.isEmpty) return [];

    // 2. Find applicable rule for this date
    final applicableRule = _findApplicableRule(rules, date);
    if (applicableRule == null || applicableRule.isBlocked) return [];

    // 3. Generate all possible slots from rule
    final allSlots = _generateSlotsFromRule(applicableRule, date);

    // 4. Get existing bookings for this date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final bookingsSnapshot = await _bookingsCollection
        .where('venueId', isEqualTo: venueId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final existingBookings = bookingsSnapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc))
        .toList();

    // 5. Mark slots as available/unavailable
    final now = DateTime.now();
    return allSlots.map((slot) {
      bool isAvailable = true;
      
      // Check for booking conflicts
      for (final booking in existingBookings) {
        if (slot.overlapsWithBooking(booking)) {
          isAvailable = false;
          break;
        }
      }

      // Check if slot is in the past (for today)
      if (_isSameDay(date, now) && slot.startAt.isBefore(now)) {
        isAvailable = false;
      }

      return TimeSlot(
        startAt: slot.startAt,
        endAt: slot.endAt,
        isAvailable: isAvailable,
      );
    }).toList();
  }

  /// Check if a specific date has available slots
  Future<bool> hasAvailableSlots({
    required String venueId,
    required DateTime date,
  }) async {
    final slots = await generateAvailableSlots(venueId: venueId, date: date);
    return slots.isNotEmpty;
  }

  /// Get dates with availability for a date range (for calendar)
  Future<Map<DateTime, bool>> getAvailabilityForDateRange({
    required String venueId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final availability = <DateTime, bool>{};
    
    for (var date = startDate;
        date.isBefore(endDate) || _isSameDay(date, endDate);
        date = date.add(const Duration(days: 1))) {
      final hasSlots = await hasAvailableSlots(venueId: venueId, date: date);
      availability[DateTime(date.year, date.month, date.day)] = hasSlots;
    }
    
    return availability;
  }

  // ==================== HELPER METHODS ====================

  /// Find the most specific applicable rule for a date
  AvailabilityRuleModel? _findApplicableRule(List<AvailabilityRuleModel> rules, DateTime date) {
    // First, check for specific date rule (highest priority)
    for (final rule in rules) {
      if (rule.type == RuleType.specificDate && 
          rule.date != null && 
          _isSameDay(rule.date!, date)) {
        return rule;
      }
    }

    // Then, check for weekly rule
    // Dart's weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
    // We store weekday the same way (1-7), so use directly
    final weekday = date.weekday;
    for (final rule in rules) {
      if (rule.type == RuleType.weekly && rule.weekday == weekday) {
        return rule;
      }
    }

    return null;
  }

  /// Generate slots from a rule for a specific date
  List<TimeSlot> _generateSlotsFromRule(AvailabilityRuleModel rule, DateTime date) {
    final slots = <TimeSlot>[];
    
    final startTime = _parseTime(rule.startTime);
    final endTime = _parseTime(rule.endTime);
    final duration = rule.slotDurationMinutes;
    final buffer = rule.bufferMinutes;

    var currentStart = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final dayEnd = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    while (currentStart.isBefore(dayEnd)) {
      final slotEnd = currentStart.add(Duration(minutes: duration));
      
      if (slotEnd.isAfter(dayEnd)) break;
      
      slots.add(TimeSlot(
        startAt: currentStart,
        endAt: slotEnd,
        isAvailable: true,
      ));
      
      // Move to next slot start (including buffer)
      currentStart = slotEnd.add(Duration(minutes: buffer));
    }

    return slots;
  }

  /// Parse time string to DateTime (uses today's date)
  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ==================== QUICK SETUP HELPERS ====================

  /// Create default weekly rules for a venue (Mon-Fri, 9am-6pm)
  Future<void> createDefaultWeeklyRules({
    required String venueId,
    String startTime = '09:00',
    String endTime = '18:00',
    int slotDuration = 60,
    int buffer = 0,
    List<int> workDays = const [1, 2, 3, 4, 5], // Mon-Fri
  }) async {
    final batch = _firestore.batch();

    for (final weekday in workDays) {
      final docRef = _rulesCollection.doc();
      final rule = AvailabilityRuleModel(
        id: docRef.id,
        venueId: venueId,
        type: RuleType.weekly,
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
        slotDurationMinutes: slotDuration,
        bufferMinutes: buffer,
        createdAt: DateTime.now(),
      );
      batch.set(docRef, rule.toMap());
    }

    await batch.commit();
  }

  /// Block a specific date
  Future<void> blockDate({
    required String venueId,
    required DateTime date,
  }) async {
    final rule = AvailabilityRuleModel(
      id: '',
      venueId: venueId,
      type: RuleType.specificDate,
      date: date,
      startTime: '00:00',
      endTime: '00:00',
      isBlocked: true,
      createdAt: DateTime.now(),
    );
    await createRule(rule);
  }

  /// Unblock a date (delete the blocking rule)
  Future<void> unblockDate({
    required String venueId,
    required DateTime date,
  }) async {
    final snapshot = await _rulesCollection
        .where('venueId', isEqualTo: venueId)
        .where('type', isEqualTo: RuleType.specificDate.name)
        .where('isBlocked', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      final rule = AvailabilityRuleModel.fromFirestore(doc);
      if (rule.date != null && _isSameDay(rule.date!, date)) {
        await doc.reference.delete();
      }
    }
  }
}
