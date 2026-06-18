import 'package:flutter_test/flutter_test.dart';
import 'package:trip_mate/data/repositories/mock/places_repository_mock.dart';
import 'package:trip_mate/data/models/place.dart';

void main() {
  group('PlacesRepositoryMock - Empty List Handling', () {
    final repository = PlacesRepositoryMock();

    test(
      'getPlacesByCity - returns empty list for non-existent city',
      () async {
        final places = await repository.getPlacesByCity('NonExistentCity');
        expect(places, isEmpty);
        expect(places, isA<List<Place>>());
      },
    );

    test(
      'getPlacesByCategory - returns empty list for non-existent category',
      () async {
        final places = await repository.getPlacesByCategory(
          'NonExistentCategory',
        );
        expect(places, isEmpty);
        expect(places, isA<List<Place>>());
      },
    );

    test('searchPlaces - returns empty list for no matches', () async {
      final places = await repository.searchPlaces('xyz123nonexistent');
      expect(places, isEmpty);
      expect(places, isA<List<Place>>());
    });

    test(
      'getPlacesByInterests - returns empty list for non-matching interests',
      () async {
        final places = await repository.getPlacesByInterests([
          'NonExistentInterest',
        ]);
        expect(places, isEmpty);
        expect(places, isA<List<Place>>());
      },
    );

    test('getRecommendedPlaces - returns empty list when no matches', () async {
      final places = await repository.getRecommendedPlaces(
        city: 'NonExistentCity',
        interests: ['NonExistentInterest'],
      );
      expect(places, isEmpty);
      expect(places, isA<List<Place>>());
    });

    test(
      'getCitiesByCountry - returns empty list for non-existent country',
      () async {
        final cities = await repository.getCitiesByCountry(
          'NonExistentCountry',
        );
        expect(cities, isEmpty);
        expect(cities, isA<List<String>>());
      },
    );

    test('getPlaceById - returns null for non-existent place', () async {
      final place = await repository.getPlaceById('non_existent_id');
      expect(place, isNull);
    });

    test('empty list operations do not throw exceptions', () async {
      expect(() => repository.getPlacesByCity('NonExistent'), returnsNormally);
      expect(
        () => repository.getPlacesByCategory('NonExistent'),
        returnsNormally,
      );
      expect(() => repository.searchPlaces('NonExistent'), returnsNormally);
      expect(
        () => repository.getPlacesByInterests(['NonExistent']),
        returnsNormally,
      );
      expect(
        () => repository.getCitiesByCountry('NonExistent'),
        returnsNormally,
      );
    });
  });
}
