/// Geoapify category mapping for app categories
/// Maps app category names to Geoapify API category strings
class GeoapifyCategoryMap {
  /// Unsupported Geoapify categories that should be filtered out
  static const Set<String> unsupportedCategories = {
    'leisure.garden', // Not supported by Geoapify API
  };

  /// Filter out unsupported categories from a list
  static List<String> filterSupportedCategories(List<String> categories) {
    return categories
        .where((cat) => !unsupportedCategories.contains(cat))
        .toList();
  }

  /// Get Geoapify categories for an app category (with unsupported ones filtered)
  static List<String> geoapifyCategoriesFor(String appCategory) {
    switch (appCategory.toLowerCase()) {
      case 'ancient':
        return [
          'tourism.attraction',
          'tourism.sights',
          'heritage',
          'entertainment.museum',
          'religion.place_of_worship',
        ];
      case 'nature':
        return filterSupportedCategories([
          'leisure.park',
          'natural.forest',
          'natural.mountain',
          'beach.beach_resort',
          'beach',
        ]);
      case 'food':
        return filterSupportedCategories([
          'catering.restaurant',
          'catering.cafe',
          'catering.fast_food',
        ]);
      case 'shopping':
        return filterSupportedCategories([
          'commercial.shopping_mall',
          'commercial.marketplace',
          'commercial.supermarket',
          'commercial.department_store',
        ]);
      case 'medical':
        return filterSupportedCategories([
          'healthcare.hospital',
          'healthcare.clinic',
          'healthcare.pharmacy',
        ]);
      default:
        // Default to Ancient if unknown category
        return filterSupportedCategories([
          'tourism.attraction',
          'tourism.sights',
          'heritage',
        ]);
    }
  }

  /// Get all available app categories (Nature moved to last position)
  static List<String> getAvailableCategories() {
    return ['Ancient', 'Food', 'Shopping', 'Medical', 'Nature'];
  }
}
