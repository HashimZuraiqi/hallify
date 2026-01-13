import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/availability_slot_model.dart';

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _slotsCollection;

  AvailabilityService() {
    _slotsCollection = _firestore.collection('availabilitySlots');
  }

  /// Generate time slots for a date range
  Future<void> generateSlotsForDateRange({
    required String hallId,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime, // "09:00"
    required String endTime, // "18:00"
    required int slotDuration, // minutes (e.g., 60)
    List<int> excludedWeekdays = const [], // 0=Sun, 6=Sat
  }) async {
    final batch = _firestore.batch();
    int batchCount = 0;

    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      // Skip excluded weekdays
      if (excludedWeekdays.contains(date.weekday % 7)) continue;

      final dateStr = _formatDate(date);
      
      // Generate time slots for this day
      final slots = _generateTimeSlotsForDay(
        startTime: startTime,
        endTime: endTime,
        duration: slotDuration,
      );

      for (var slot in slots) {
        final docRef = _slotsCollection.doc();
        final slotModel = AvailabilitySlotModel(
          id: docRef.id,
          hallId: hallId,
          date: dateStr,
          startTime: slot['start']!,
          endTime: slot['end']!,
          duration: slotDuration,
          isAvailable: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        batch.set(docRef, slotModel.toMap());
        batchCount++;

        // Firestore batch limit is 500
        if (batchCount >= 450) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }

  /// Get available slots for a specific date and hall
  Future<List<AvailabilitySlotModel>> getAvailableSlotsForDate({
    required String hallId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final snapshot = await _slotsCollection
        .where('hallId', isEqualTo: hallId)
        .where('date', isEqualTo: dateStr)
        .where('isAvailable', isEqualTo: true)
        .orderBy('startTime')
        .get();

    return snapshot.docs
        .map((doc) => AvailabilitySlotModel.fromFirestore(doc))
        .toList();
  }

  /// Get all slots (available and booked) for a date
  Future<List<AvailabilitySlotModel>> getAllSlotsForDate({
    required String hallId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final snapshot = await _slotsCollection
        .where('hallId', isEqualTo: hallId)
        .where('date', isEqualTo: dateStr)
        .orderBy('startTime')
        .get();

    return snapshot.docs
        .map((doc) => AvailabilitySlotModel.fromFirestore(doc))
        .toList();
  }

  /// Toggle slot availability
  Future<void> toggleSlotAvailability(String slotId, bool isAvailable) async {
    await _slotsCollection.doc(slotId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark slot as booked (when visit is approved)
  Future<void> markSlotAsBooked({
    required String slotId,
    required String userId,
    required String visitId,
  }) async {
    await _slotsCollection.doc(slotId).update({
      'isAvailable': false,
      'bookedBy': userId,
      'visitId': visitId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Free slot (when visit is cancelled/rejected)
  Future<void> freeSlot(String slotId) async {
    await _slotsCollection.doc(slotId).update({
      'isAvailable': true,
      'bookedBy': null,
      'visitId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Free slot by visitId
  Future<void> freeSlotByVisitId(String visitId) async {
    final snapshot = await _slotsCollection
        .where('visitId', isEqualTo: visitId)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isAvailable': true,
        'bookedBy': null,
        'visitId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Block entire day
  Future<void> blockDay(String hallId, DateTime date) async {
    final dateStr = _formatDate(date);
    final snapshot = await _slotsCollection
        .where('hallId', isEqualTo: hallId)
        .where('date', isEqualTo: dateStr)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isAvailable': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Unblock entire day
  Future<void> unblockDay(String hallId, DateTime date) async {
    final dateStr = _formatDate(date);
    final snapshot = await _slotsCollection
        .where('hallId', isEqualTo: hallId)
        .where('date', isEqualTo: dateStr)
        .where('bookedBy', isEqualTo: null) // Only unblock slots that aren't booked
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isAvailable': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Delete all slots for a hall
  Future<void> deleteAllSlotsForHall(String hallId) async {
    final snapshot = await _slotsCollection
        .where('hallId', isEqualTo: hallId)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ===================== HELPER METHODS =====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, String>> _generateTimeSlotsForDay({
    required String startTime,
    required String endTime,
    required int duration,
  }) {
    final slots = <Map<String, String>>[];
    
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    var current = start;
    while (current.isBefore(end)) {
      final slotEnd = current.add(Duration(minutes: duration));
      if (slotEnd.isAfter(end)) break;
      
      slots.add({
        'start': _formatTime(current),
        'end': _formatTime(slotEnd),
      });
      
      current = slotEnd;
    }
    
    return slots;
  }

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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
