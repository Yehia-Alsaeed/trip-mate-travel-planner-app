/// Validation helper for Trip model
class TripValidator {
  /// Validate trip creation data
  static String? validateCity(String? city) {
    if (city == null || city.trim().isEmpty) {
      return 'City is required';
    }
    return null;
  }

  static String? validateBudget(String? budget) {
    if (budget == null || budget.trim().isEmpty) {
      return 'Budget is required';
    }
    final budgetValue = double.tryParse(budget.trim());
    if (budgetValue == null) {
      return 'must enter a number';
    }
    if (budgetValue < 0) {
      return 'Budget must be positive';
    }
    return null;
  }

  static String? validateDates(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) {
      return 'Start date is required';
    }
    if (endDate == null) {
      return 'End date is required';
    }
    if (endDate.isBefore(startDate)) {
      return 'End date must be after start date';
    }
    return null;
  }

  static String? validateInterests(List<String> interests) {
    if (interests.isEmpty) {
      return 'At least one interest is required';
    }
    return null;
  }

  static String? validateConfirmation(bool confirmed) {
    if (!confirmed) {
      return 'Please confirm the information is correct';
    }
    return null;
  }

  /// Validate complete trip data
  static Map<String, String?> validateTripData({
    String? city,
    String? budget,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? interests,
    bool? confirmed,
  }) {
    return {
      'city': validateCity(city),
      'budget': validateBudget(budget),
      'dates': validateDates(startDate, endDate),
      'interests': validateInterests(interests ?? []),
      'confirmation': validateConfirmation(confirmed ?? false),
    };
  }
}
