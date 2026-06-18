import 'package:flutter/material.dart';
import '../models/planner_item.dart';

abstract class PlannerRepository {
  // Create a new planner item
  Future<PlannerItem> createPlannerItem(PlannerItem item);

  // Get all planner items for a trip
  Future<List<PlannerItem>> getPlannerItemsByTripId(String tripId);

  // Get planner items for a specific date
  Future<List<PlannerItem>> getPlannerItemsByDate(String tripId, DateTime date);

  // Get a specific planner item by ID
  Future<PlannerItem?> getPlannerItemById(String itemId);

  // Update a planner item
  Future<void> updatePlannerItem(PlannerItem item);

  // Delete a planner item
  Future<void> deletePlannerItem(String itemId);

  // Delete all planner items for a trip
  Future<void> deletePlannerItemsByTripId(String tripId);

  // Check if a time slot overlaps with existing items
  Future<bool> hasOverlap(
    String tripId,
    DateTime date,
    TimeOfDay startTime,
    Duration duration, {
    String? excludeItemId,
  });
}
