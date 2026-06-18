import 'package:flutter/material.dart';
import '../models/planner_item.dart';

/// Pure function for overlap detection
class OverlapDetector {
  /// Check if two planner items overlap
  static bool hasOverlap(PlannerItem item1, PlannerItem item2) {
    return item1.overlapsWith(item2);
  }

  /// Check if a new time slot overlaps with existing items
  static bool checkOverlap(
    DateTime date,
    TimeOfDay startTime,
    Duration duration,
    List<PlannerItem> existingItems, {
    String? excludeItemId,
  }) {
    final newItem = PlannerItem(
      id: excludeItemId ?? '',
      tripId: '',
      placeId: '',
      date: date,
      startTime: startTime,
      duration: duration,
      createdAt: DateTime.now(),
    );

    for (final item in existingItems) {
      if (excludeItemId != null && item.id == excludeItemId) {
        continue;
      }
      if (newItem.overlapsWith(item)) {
        return true;
      }
    }
    return false;
  }

  /// Get all overlapping items for a given time slot
  static List<PlannerItem> getOverlappingItems(
    DateTime date,
    TimeOfDay startTime,
    Duration duration,
    List<PlannerItem> existingItems, {
    String? excludeItemId,
  }) {
    final newItem = PlannerItem(
      id: excludeItemId ?? '',
      tripId: '',
      placeId: '',
      date: date,
      startTime: startTime,
      duration: duration,
      createdAt: DateTime.now(),
    );

    return existingItems.where((item) {
      if (excludeItemId != null && item.id == excludeItemId) {
        return false;
      }
      return newItem.overlapsWith(item);
    }).toList();
  }
}
