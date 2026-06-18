import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_profile_repository.dart';
import '../data/repositories/firebase/user_profile_repository_firestore.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileRepository _profileRepository =
      UserProfileRepositoryFirestore();

  bool _hasSeenGetStarted = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _userProfile;

  bool get isAuthenticated {
    try {
      final user = _auth.currentUser;
      final isAuth = user != null;
      if (isAuth) {
        debugPrint('User is authenticated: ${user.uid}');
      }
      return isAuth;
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      return false;
    }
  }

  bool get hasSeenGetStarted => _hasSeenGetStarted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get userId {
    try {
      return _auth.currentUser?.uid;
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  String? get userName => _userProfile?.name;
  String? get userFirstName => _userProfile?.firstName;

  AuthViewModel() {
    // Listen to auth state changes with error handling
    try {
      _auth.authStateChanges().listen(
        (User? user) {
          debugPrint('Auth state changed. User: ${user?.uid ?? 'null'}');
          if (user != null) {
            // Load user profile when user logs in (fire and forget)
            loadUserProfile();
          } else {
            _userProfile = null;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Auth state listener error: $error');
        },
      );

      // Also check initial auth state
      final currentUser = _auth.currentUser;
      debugPrint('Initial auth state - User: ${currentUser?.uid ?? 'null'}');
      if (currentUser != null) {
        // Load profile for current user
        loadUserProfile();
      }
    } catch (e) {
      debugPrint('Error setting up auth state listener: $e');
    }
  }

  // Load user profile from Firestore
  Future<void> loadUserProfile() async {
    final uid = userId;
    if (uid == null) {
      _userProfile = null;
      return;
    }

    try {
      _userProfile = await _profileRepository.getUserProfile(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userProfile = null;
    }
  }

  // Update user name
  Future<bool> updateUserName(String newName) async {
    final uid = userId;
    if (uid == null) {
      _errorMessage = 'User not logged in';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.updateUserName(uid, newName);

      // Update local profile
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
      } else {
        // If profile doesn't exist, create it
        final email = _auth.currentUser?.email ?? '';
        _userProfile = UserProfile(
          userId: uid,
          name: newName,
          email: email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _profileRepository.saveUserProfile(_userProfile!);
      }

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update name: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void markGetStartedSeen() {
    _hasSeenGetStarted = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Attempting to login with email: ${email.trim()}');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('Login successful! User ID: ${userCredential.user!.uid}');
        debugPrint('Current user after login: ${_auth.currentUser?.uid}');
        _errorMessage = null;
        // Force notify listeners to update UI
        notifyListeners();
        // Wait a moment for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 200));
        // Notify again to ensure navigation happens
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          _errorMessage =
              'No user found with this email. Please sign up first.';
          break;
        case 'wrong-password':
          _errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          _errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many requests. Please try again later.';
          break;
        case 'operation-not-allowed':
          _errorMessage =
              'Email/password accounts are not enabled in Firebase. Please enable it in Firebase Console.';
          break;
        case 'network-request-failed':
          _errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          _errorMessage = 'Login failed: ${e.message ?? e.code}';
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Handle the specific type cast error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        _errorMessage =
            'Authentication error. Please try again or restart the app.';
        debugPrint('Type cast error detected - this may require app restart');
      } else {
        _errorMessage = 'Login failed: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Attempting to register with email: ${email.trim()}');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint(
          'Registration successful! User ID: ${userCredential.user!.uid}',
        );
        debugPrint(
          'Current user after registration: ${_auth.currentUser?.uid}',
        );

        // Save user profile with name
        final profile = UserProfile(
          userId: userCredential.user!.uid,
          name: name.trim(),
          email: email.trim(),
          createdAt: DateTime.now(),
        );
        await _profileRepository.saveUserProfile(profile);
        _userProfile = profile;

        _errorMessage = null;
        // Force notify listeners to update UI
        notifyListeners();
        // Wait a moment for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 200));
        // Notify again to ensure state is updated
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          _errorMessage =
              'The password provided is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          _errorMessage =
              'An account already exists with this email. Please login instead.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          _errorMessage =
              'Email/password accounts are not enabled in Firebase. Please enable it in Firebase Console.';
          break;
        case 'network-request-failed':
          _errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          _errorMessage = 'Registration failed: ${e.message ?? e.code}';
      }
    } catch (e, stackTrace) {
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Handle the specific type cast error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        _errorMessage =
            'Authentication error. Please try again or restart the app.';
        debugPrint('Type cast error detected - this may require app restart');
      } else {
        _errorMessage = 'Registration failed: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
