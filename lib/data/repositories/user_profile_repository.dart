import '../models/user_profile.dart';

abstract class UserProfileRepository {
  // Create or update a user profile
  Future<void> saveUserProfile(UserProfile profile);

  // Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId);

  // Update user name
  Future<void> updateUserName(String userId, String name);
}
