import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../user_profile_repository.dart';

class UserProfileRepositoryFirestore implements UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'userProfiles';

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(profile.userId)
          .set(profile.toMap());
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  @override
  Future<void> updateUserName(String userId, String name) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'name': name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update user name: $e');
    }
  }
}
