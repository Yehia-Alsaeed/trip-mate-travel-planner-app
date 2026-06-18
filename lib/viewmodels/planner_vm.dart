import 'package:flutter/material.dart';
import '../data/models/planner_item.dart';
import '../data/models/place.dart';
import '../data/repositories/planner_repository.dart';
import '../data/repositories/firebase/planner_repository_firestore.dart';

class PlannerViewModel extends ChangeNotifier {
  final PlannerRepository _repository = PlannerRepositoryFirestore();

  bool _isLoading = false;
  String? _errorMessage;
  List<PlannerItem> _plannerItems = [];
  String? _selectedTripId;
  bool _isLoadingForTrip =
      false; // Guard to prevent multiple simultaneous loads

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PlannerItem> get plannerItems => _plannerItems;
  String? get selectedTripId => _selectedTripId;

  // Load planner items for a trip
  Future<void> loadPlannerItems(String tripId) async {
    // Guard: if already loading for this trip or already loaded, skip
    if (_isLoadingForTrip ||
        (_selectedTripId == tripId && _plannerItems.isNotEmpty)) {
      return;
    }

    _selectedTripId = tripId;
    _isLoading = true;
    _isLoadingForTrip = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plannerItems = await _repository.getPlannerItemsByTripId(tripId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load planner items: ${e.toString()}';
      _plannerItems = [];
    } finally {
      _isLoading = false;
      _isLoadingForTrip = false;
      notifyListeners();
    }
  }

  // Get planner items for a specific date
  Future<List<PlannerItem>> getPlannerItemsByDate(DateTime date) async {
    if (_selectedTripId == null) return [];

    try {
      return await _repository.getPlannerItemsByDate(_selectedTripId!, date);
    } catch (e) {
      _errorMessage = 'Failed to load planner items for date: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  // Add a planner item
  Future<bool> addPlannerItem({
    required String tripId,
    required String placeId,
    required DateTime date,
    required TimeOfDay startTime,
    required Duration duration,
    Place? place, // Optional Place object to store
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check for overlap
      final hasOverlap = await _repository.hasOverlap(
        tripId,
        date,
        startTime,
        duration,
      );

      if (hasOverlap) {
        _errorMessage = 'This time slot overlaps with an existing item';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newItem = PlannerItem(
        id: '', // Will be set by repository
        tripId: tripId,
        placeId: placeId,
        date: date,
        startTime: startTime,
        duration: duration,
        createdAt: DateTime.now(),
        place: place, // Store Place object
      );

      final createdItem = await _repository.createPlannerItem(newItem);

      if (_selectedTripId == tripId) {
        _plannerItems.add(createdItem);
        _plannerItems.sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          final timeCompare = a.startTime.hour.compareTo(b.startTime.hour);
          if (timeCompare != 0) return timeCompare;
          return a.startTime.minute.compareTo(b.startTime.minute);
        });
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add planner item: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a planner item
  Future<bool> updatePlannerItem({
    required PlannerItem item,
    DateTime? newDate,
    TimeOfDay? newStartTime,
    Duration? newDuration,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = item.copyWith(
        date: newDate ?? item.date,
        startTime: newStartTime ?? item.startTime,
        duration: newDuration ?? item.duration,
      );

      // Check for overlap (excluding the item being updated)
      final hasOverlap = await _repository.hasOverlap(
        item.tripId,
        updatedItem.date,
        updatedItem.startTime,
        updatedItem.duration,
        excludeItemId: item.id,
      );

      if (hasOverlap) {
        _errorMessage = 'This time slot overlaps with an existing item';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _repository.updatePlannerItem(updatedItem);

      final index = _plannerItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _plannerItems[index] = updatedItem;
        _plannerItems.sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          final timeCompare = a.startTime.hour.compareTo(b.startTime.hour);
          if (timeCompare != 0) return timeCompare;
          return a.startTime.minute.compareTo(b.startTime.minute);
        });
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update planner item: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a planner item
  Future<bool> deletePlannerItem(String itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deletePlannerItem(itemId);
      _plannerItems.removeWhere((i) => i.id == itemId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete planner item: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if a time slot has overlap (pure function for UI validation)
  bool checkOverlapLocally(
    DateTime date,
    TimeOfDay startTime,
    Duration duration, {
    String? excludeItemId,
  }) {
    final newItem = PlannerItem(
      id: excludeItemId ?? '',
      tripId: _selectedTripId ?? '',
      placeId: '',
      date: date,
      startTime: startTime,
      duration: duration,
      createdAt: DateTime.now(),
    );

    for (final item in _plannerItems) {
      if (excludeItemId != null && item.id == excludeItemId) {
        continue;
      }
      if (newItem.overlapsWith(item)) {
        return true;
      }
    }
    return false;
  }

  // Get items grouped by date
  Map<DateTime, List<PlannerItem>> getItemsByDate() {
    final Map<DateTime, List<PlannerItem>> grouped = {};

    for (final item in _plannerItems) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(item);
    }

    // Sort items within each date by time
    for (final date in grouped.keys) {
      grouped[date]!.sort((a, b) {
        final timeCompare = a.startTime.hour.compareTo(b.startTime.hour);
        if (timeCompare != 0) return timeCompare;
        return a.startTime.minute.compareTo(b.startTime.minute);
      });
    }

    return grouped;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
