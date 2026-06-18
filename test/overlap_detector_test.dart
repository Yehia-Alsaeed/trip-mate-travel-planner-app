import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_mate/data/helpers/overlap_detector.dart';
import 'package:trip_mate/data/models/planner_item.dart';

void main() {
  group('OverlapDetector', () {
    final baseDate = DateTime(2024, 1, 1);

    test('checkOverlap - no overlap for different days', () {
      final existingItems = [
        PlannerItem(
          id: '1',
          tripId: 'trip1',
          placeId: 'place1',
          date: baseDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          duration: const Duration(hours: 2),
          createdAt: DateTime.now(),
        ),
      ];

      final hasOverlap = OverlapDetector.checkOverlap(
        DateTime(2024, 1, 2), // Different day
        const TimeOfDay(hour: 10, minute: 0),
        const Duration(hours: 2),
        existingItems,
      );

      expect(hasOverlap, isFalse);
    });

    test('checkOverlap - detects overlap for same time', () {
      final existingItems = [
        PlannerItem(
          id: '1',
          tripId: 'trip1',
          placeId: 'place1',
          date: baseDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          duration: const Duration(hours: 2),
          createdAt: DateTime.now(),
        ),
      ];

      final hasOverlap = OverlapDetector.checkOverlap(
        baseDate,
        const TimeOfDay(hour: 10, minute: 0),
        const Duration(hours: 2),
        existingItems,
      );

      expect(hasOverlap, isTrue);
    });

    test('checkOverlap - detects overlap for overlapping times', () {
      final existingItems = [
        PlannerItem(
          id: '1',
          tripId: 'trip1',
          placeId: 'place1',
          date: baseDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          duration: const Duration(hours: 2), // 10:00 - 12:00
          createdAt: DateTime.now(),
        ),
      ];

      // New item: 11:00 - 13:00 (overlaps)
      final hasOverlap = OverlapDetector.checkOverlap(
        baseDate,
        const TimeOfDay(hour: 11, minute: 0),
        const Duration(hours: 2),
        existingItems,
      );

      expect(hasOverlap, isTrue);
    });

    test('checkOverlap - no overlap for adjacent times', () {
      final existingItems = [
        PlannerItem(
          id: '1',
          tripId: 'trip1',
          placeId: 'place1',
          date: baseDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          duration: const Duration(hours: 2), // 10:00 - 12:00
          createdAt: DateTime.now(),
        ),
      ];

      // New item: 12:00 - 14:00 (adjacent, no overlap)
      final hasOverlap = OverlapDetector.checkOverlap(
        baseDate,
        const TimeOfDay(hour: 12, minute: 0),
        const Duration(hours: 2),
        existingItems,
      );

      expect(hasOverlap, isFalse);
    });

    test('checkOverlap - excludes item when excludeItemId is provided', () {
      final existingItems = [
        PlannerItem(
          id: '1',
          tripId: 'trip1',
          placeId: 'place1',
          date: baseDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          duration: const Duration(hours: 2),
          createdAt: DateTime.now(),
        ),
      ];

      // Check overlap with same time but exclude the item
      final hasOverlap = OverlapDetector.checkOverlap(
        baseDate,
        const TimeOfDay(hour: 10, minute: 0),
        const Duration(hours: 2),
        existingItems,
        excludeItemId: '1',
      );

      expect(hasOverlap, isFalse);
    });

    test('getOverlappingItems - returns all overlapping items', () {
      final existingItems = [
        PlannerItem(
          id: '1',
          tripId: 'trip1',
          placeId: 'place1',
          date: baseDate,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          duration: const Duration(hours: 2),
          createdAt: DateTime.now(),
        ),
        PlannerItem(
          id: '2',
          tripId: 'trip1',
          placeId: 'place2',
          date: baseDate,
          startTime: const TimeOfDay(hour: 14, minute: 0),
          duration: const Duration(hours: 1),
          createdAt: DateTime.now(),
        ),
        PlannerItem(
          id: '3',
          tripId: 'trip1',
          placeId: 'place3',
          date: baseDate,
          startTime: const TimeOfDay(hour: 11, minute: 0),
          duration: const Duration(hours: 1),
          createdAt: DateTime.now(),
        ),
      ];

      final overlapping = OverlapDetector.getOverlappingItems(
        baseDate,
        const TimeOfDay(hour: 10, minute: 30),
        const Duration(hours: 2),
        existingItems,
      );

      expect(overlapping.length, 2); // Items 1 and 3 overlap
      expect(overlapping.any((item) => item.id == '1'), isTrue);
      expect(overlapping.any((item) => item.id == '3'), isTrue);
    });
  });
}
