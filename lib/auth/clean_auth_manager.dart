import '../models/user.dart';
import '../services/insforge_client.dart';

class CleanAuthManager {
  static final CleanAuthManager _instance = CleanAuthManager._internal();
  factory CleanAuthManager() => _instance;
  CleanAuthManager._internal();

  static CleanAuthManager get instance => _instance;

  final InsforgeClient _client = InsforgeClient.instance;

  // Expose client for external use
  InsforgeClient get client => _client;

  Future<User?> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      print('Starting sign up for: $email');

      final authResult = await _client.signUp(
        email: email,
        password: password,
      );

      if (authResult == null) {
        print('Sign up failed: No auth result');
        return null;
      }

      print('Sign up successful, setting profile...');

      final profileResult = await _client.setProfile(
        nickname: nickname,
        bio: null,
        avatarUrl: null,
      );

      if (profileResult == null) {
        print('Profile setup failed, but user created');
      }

      return await getCurrentUser();
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Starting sign in for: $email');

      final authResult = await _client.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResult == null) {
        print('Sign in failed: No auth result');
        return null;
      }

      print('Sign in successful');
      final user = await getCurrentUser();
      return user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final userData = await _client.getCurrentUser();
      if (userData == null) {
        return null;
      }

      // Extract user information from the response
      String userId;
      String email;
      String? name;
      Map<String, dynamic>? profileData;

      if (userData.containsKey('user')) {
        // Standard format: { user: {...}, profile: {...} }
        final userMap = userData['user'] as Map<String, dynamic>;
        userId = userMap['id'] as String;
        email = userMap['email'] as String;
        name = userMap['name'] as String?;

        // Try to get profile data
        if (userData.containsKey('profile') && userData['profile'] != null) {
          profileData = userData['profile'] as Map<String, dynamic>?;
        }
      } else if (userData.containsKey('id') && userData.containsKey('email')) {
        // Direct format: { id: ..., email: ..., nickname: ... }
        userId = userData['id'] as String;
        email = userData['email'] as String;
        name = userData['name'] as String?;
        profileData = userData;
      } else {
        // Fallback: can't parse user data
        // print('Unable to parse user data: $userData');
        return null;
      }

      // If we don't have profile data, try to fetch it from the users table directly
      if (profileData == null) {
        try {
          final users = await _client.select(
            table: 'users',
            filters: {'id': userId},
          );

          if (users.isNotEmpty) {
            profileData = users.first;
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }

      return User(
        id: userId,
        email: email,
        nickname: profileData?['nickname'] ?? name ?? email.split('@')[0],
        bio: profileData?['bio'] ?? '',
        avatarUrl: profileData?['avatar_url'],
        birthday: profileData?['birthday'] != null
            ? DateTime.parse(profileData!['birthday'])
            : null,
        createdAt: profileData?['created_at'] != null
            ? DateTime.parse(profileData!['created_at'])
            : DateTime.now(),
        updatedAt: profileData?['updated_at'] != null
            ? DateTime.parse(profileData!['updated_at'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<User?> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
    String? birthday,
  }) async {
    try {
      final result = await _client.setProfile(
        nickname: nickname,
        bio: bio,
        avatarUrl: avatarUrl,
        birthday: birthday,
      );

      if (result != null) {
        return await getCurrentUser();
      }
      return null;
    } catch (e) {
      print('Update profile error: $e');
      return null;
    }
  }

  Future<User?> getUserProfile(String userId) async {
    try {
      // Get user profile from database
      final users = await _client.select(
        table: 'users',
        filters: {'id': userId},
      );

      if (users.isNotEmpty) {
        final userData = users.first;
        return User(
          id: userData['id'],
          email: '', // Email not available in users table
          nickname: userData['nickname'] ?? '',
          bio: userData['bio'] ?? '',
          avatarUrl: userData['avatar_url'],
          birthday: userData['birthday'],
          createdAt: userData['created_at'] != null
              ? DateTime.parse(userData['created_at'])
              : DateTime.now(),
          updatedAt: userData['updated_at'] != null
              ? DateTime.parse(userData['updated_at'])
              : DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      // print('Get user profile error: $e');
      return null;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      // For now, just sign out since Insforge doesn't have deleteAccount
      await _client.signOut();
      return true;
    } catch (e) {
      print('Delete account error: $e');
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      print('Check authentication error: $e');
      return false;
    }
  }

  Stream<User?> get authStateChanges async* {
    // Only emit once to avoid infinite loops
    yield await getCurrentUser();
  }
}
