import 'package:flutter_test/flutter_test.dart';
import 'package:trip_mate/data/helpers/trip_validator.dart';

void main() {
  group('TripValidator', () {
    test('validateCity - returns null for valid city', () {
      expect(TripValidator.validateCity('Cairo'), isNull);
      expect(TripValidator.validateCity('New York'), isNull);
    });

    test('validateCity - returns error for empty city', () {
      expect(TripValidator.validateCity(null), isNotNull);
      expect(TripValidator.validateCity(''), isNotNull);
      expect(TripValidator.validateCity('   '), isNotNull);
    });

    test('validateBudget - returns null for valid budget', () {
      expect(TripValidator.validateBudget('100'), isNull);
      expect(TripValidator.validateBudget('1000.50'), isNull);
    });

    test('validateBudget - returns error for invalid budget', () {
      expect(TripValidator.validateBudget(null), isNotNull);
      expect(TripValidator.validateBudget(''), isNotNull);
      expect(TripValidator.validateBudget('abc'), isNotNull);
      expect(TripValidator.validateBudget('-100'), isNotNull);
    });

    test('validateDates - returns null for valid dates', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 5);
      expect(TripValidator.validateDates(start, end), isNull);
    });

    test('validateDates - returns error for invalid dates', () {
      final start = DateTime(2024, 1, 5);
      final end = DateTime(2024, 1, 1);
      expect(TripValidator.validateDates(null, end), isNotNull);
      expect(TripValidator.validateDates(start, null), isNotNull);
      expect(TripValidator.validateDates(start, end), isNotNull);
    });

    test('validateInterests - returns null for valid interests', () {
      expect(TripValidator.validateInterests(['Ancient']), isNull);
      expect(TripValidator.validateInterests(['Ancient', 'Nature']), isNull);
    });

    test('validateInterests - returns error for empty interests', () {
      expect(TripValidator.validateInterests([]), isNotNull);
    });

    test('validateConfirmation - returns null for confirmed', () {
      expect(TripValidator.validateConfirmation(true), isNull);
    });

    test('validateConfirmation - returns error for not confirmed', () {
      expect(TripValidator.validateConfirmation(false), isNotNull);
    });

    test('validateTripData - returns all null for valid data', () {
      final result = TripValidator.validateTripData(
        city: 'Cairo',
        budget: '1000',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
        interests: ['Ancient'],
        confirmed: true,
      );
      expect(result.values.every((v) => v == null), isTrue);
    });

    test('validateTripData - returns errors for invalid data', () {
      final result = TripValidator.validateTripData(
        city: '',
        budget: 'abc',
        startDate: null,
        endDate: null,
        interests: [],
        confirmed: false,
      );
      expect(result.values.any((v) => v != null), isTrue);
    });
  });
}
