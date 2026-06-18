import 'package:flutter/material.dart';

/// Helper class for consistent error handling and display
class ErrorHandler {
  /// Show error message as SnackBar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success message as SnackBar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error from ViewModel
  static void showViewModelError(BuildContext context, String? errorMessage) {
    if (errorMessage != null && errorMessage.isNotEmpty) {
      showError(context, errorMessage);
    }
  }
}
