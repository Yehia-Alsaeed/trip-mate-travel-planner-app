import 'package:flutter/material.dart';
import 'place.dart';

class PlannerItem {
  final String id;
  final String tripId;
  final String placeId;
  final DateTime date; // Which day in the trip
  final TimeOfDay startTime; // Start time (hour, minute)
  final Duration duration; // How long the visit lasts
  final DateTime createdAt;
  final Place? place; // Stored Place object for display

  PlannerItem({
    required this.id,
    required this.tripId,
    required this.placeId,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.createdAt,
    this.place,
  });

  // Calculate end time
  DateTime get endTime {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    return start.add(duration);
  }

  // Check if this item overlaps with another item
  bool overlapsWith(PlannerItem other) {
    if (date.year != other.date.year ||
        date.month != other.date.month ||
        date.day != other.date.day) {
      return false; // Different days, no overlap
    }

    final thisStart = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final thisEnd = thisStart.add(duration);

    final otherStart = DateTime(
      other.date.year,
      other.date.month,
      other.date.day,
      other.startTime.hour,
      other.startTime.minute,
    );
    final otherEnd = otherStart.add(other.duration);

    // Check for overlap: thisStart < otherEnd && thisEnd > otherStart
    return thisStart.isBefore(otherEnd) && thisEnd.isAfter(otherStart);
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'placeId': placeId,
      'date': date.toIso8601String(),
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'durationMinutes': duration.inMinutes,
      'createdAt': createdAt.toIso8601String(),
      'place': place?.toMap(), // Store full Place object
    };
  }

  // Create from Firestore document
  factory PlannerItem.fromMap(String id, Map<String, dynamic> map) {
    final date = DateTime.parse(map['date'] as String);

    // Parse Place object if available
    Place? placeObj;
    if (map['place'] != null && map['place'] is Map) {
      try {
        placeObj = Place.fromMap(map['place'] as Map<String, dynamic>);
      } catch (e) {
        // If parsing fails, leave it null
        placeObj = null;
      }
    }

    return PlannerItem(
      id: id,
      tripId: map['tripId'] as String,
      placeId: map['placeId'] as String,
      date: date,
      startTime: TimeOfDay(
        hour: map['startTimeHour'] as int,
        minute: map['startTimeMinute'] as int,
      ),
      duration: Duration(minutes: map['durationMinutes'] as int),
      createdAt: DateTime.parse(map['createdAt'] as String),
      place: placeObj,
    );
  }

  // Create a copy with updated fields
  PlannerItem copyWith({
    String? id,
    String? tripId,
    String? placeId,
    DateTime? date,
    TimeOfDay? startTime,
    Duration? duration,
    DateTime? createdAt,
    Place? place,
  }) {
    return PlannerItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      placeId: placeId ?? this.placeId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      place: place ?? this.place,
    );
  }
}
