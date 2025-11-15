import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/services/insforge_client.dart';

// Insforge Authentication Manager for Campus Pulse
// Handles email/password authentication with Insforge backend
class InsforgeAuthManager {
  static final InsforgeAuthManager _instance = InsforgeAuthManager._();
  static InsforgeAuthManager get instance => _instance;
  InsforgeAuthManager._();

  final InsforgeClient _client = InsforgeClient.instance;

  // Initialize the auth manager
  Future<void> initialize() async {
    // InsforgeClient doesn't need initialization
  }

  // Get current authenticated user
  Future<User?> getCurrentUser() async {
    try {
      final authData = await _client.getCurrentUser();
      if (authData == null) return null;
      
      // Extract user data from auth response
      Map<String, dynamic> userData;
      if (authData['user'] != null) {
        userData = authData['user'] as Map<String, dynamic>;
      } else {
        userData = authData;
      }
      
      // Ensure we have the user ID
      if (userData['id'] == null) {
        print('No user ID found in auth data');
        return null;
      }
      
      return User.fromInsforgeAuth(userData);
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      // Sign up with Insforge
      await _client.signUp(
        email: email,
        password: password,
      );

      // Update profile with nickname
      await _client.setProfile(nickname: nickname);

      // Get the updated user data
      final userData = await _client.getCurrentUser();
      if (userData == null) return null;

      return User.fromInsforgeAuth(userData);
    } catch (e) {
      print('Sign up error: $e');
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<User?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Insforge
      await _client.signInWithPassword(
        email: email,
        password: password,
      );

      // Get the user data
      final userData = await _client.getCurrentUser();
      if (userData == null) return null;

      return User.fromInsforgeAuth(userData);
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  // Update user profile
  Future<User?> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      await _client.setProfile(
        nickname: nickname,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      // Get the updated user data
      final userData = await _client.getCurrentUser();
      if (userData == null) return null;

      return User.fromInsforgeAuth(userData);
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get any user's profile by ID
  Future<User?> getUserProfile(String userId) async {
    try {
      final users = await _client.select(
        table: 'users',
        filters: {'id': userId},
      );
      if (users.isNotEmpty) {
        return User.fromJson(users.first);
      }
      return null;
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      // For now, just sign out - account deletion would require backend implementation
      await _client.signOut();
      return true;
    } catch (e) {
      print('Delete account error: $e');
      return false;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated {
    // This should be async but the interface requires sync
    // We'll return false and let the caller check with getCurrentUser()
    return false;
  }

  // Stream for auth state changes (simplified version)
  Stream<User?> get authStateChanges async* {
    // Only emit once to avoid infinite loops
    yield await getCurrentUser();
  }
}