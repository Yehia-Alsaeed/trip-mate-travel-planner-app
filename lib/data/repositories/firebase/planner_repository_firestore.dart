import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/planner_item.dart';
import '../planner_repository.dart';

class PlannerRepositoryFirestore implements PlannerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'plannerItems';

  @override
  Future<PlannerItem> createPlannerItem(PlannerItem item) async {
    try {
      final docRef = await _firestore.collection(_collection).add(item.toMap());
      return item.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create planner item: $e');
    }
  }

  @override
  Future<List<PlannerItem>> getPlannerItemsByTripId(String tripId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('tripId', isEqualTo: tripId)
              .orderBy('date')
              .orderBy('startTimeHour')
              .orderBy('startTimeMinute')
              .get();

      return querySnapshot.docs
          .map((doc) => PlannerItem.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get planner items: $e');
    }
  }

  @override
  Future<List<PlannerItem>> getPlannerItemsByDate(
    String tripId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('tripId', isEqualTo: tripId)
              .where(
                'date',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
              )
              .where('date', isLessThan: endOfDay.toIso8601String())
              .orderBy('date')
              .orderBy('startTimeHour')
              .orderBy('startTimeMinute')
              .get();

      return querySnapshot.docs
          .map((doc) => PlannerItem.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get planner items by date: $e');
    }
  }

  @override
  Future<PlannerItem?> getPlannerItemById(String itemId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(itemId).get();
      if (!doc.exists) return null;
      return PlannerItem.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get planner item: $e');
    }
  }

  @override
  Future<void> updatePlannerItem(PlannerItem item) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(item.id)
          .update(item.toMap());
    } catch (e) {
      throw Exception('Failed to update planner item: $e');
    }
  }

  @override
  Future<void> deletePlannerItem(String itemId) async {
    try {
      await _firestore.collection(_collection).doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete planner item: $e');
    }
  }

  @override
  Future<void> deletePlannerItemsByTripId(String tripId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('tripId', isEqualTo: tripId)
              .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete planner items: $e');
    }
  }

  @override
  Future<bool> hasOverlap(
    String tripId,
    DateTime date,
    TimeOfDay startTime,
    Duration duration, {
    String? excludeItemId,
  }) async {
    try {
      final items = await getPlannerItemsByDate(tripId, date);

      final newItem = PlannerItem(
        id: excludeItemId ?? '',
        tripId: tripId,
        placeId: '',
        date: date,
        startTime: startTime,
        duration: duration,
        createdAt: DateTime.now(),
      );

      for (final item in items) {
        if (excludeItemId != null && item.id == excludeItemId) {
          continue; // Skip the item being updated
        }
        if (newItem.overlapsWith(item)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check overlap: $e');
    }
  }
}
