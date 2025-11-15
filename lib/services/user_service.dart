import '../models/user.dart';
import 'insforge_client.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static UserService get instance => _instance;

  final InsforgeClient _client = InsforgeClient.instance;

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final usersData = await _client.select(
        table: 'users',
        orderBy: 'created_at.desc',
      );

      return usersData.map((data) => User.fromJson(data)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final usersData = await _client.select(
        table: 'users',
        filters: {'id': userId},
      );

      if (usersData.isNotEmpty) {
        // Get user's posts count
        final postsData = await _client.select(
          table: 'posts',
          filters: {'user_id': userId},
        );

        // Get user's total fires received
        int totalFires = 0;
        for (final post in postsData) {
          totalFires += post['fires_count'] as int? ?? 0;
        }

        // Update the user data with current stats
        final userData = usersData.first;
        final updatedUserData = Map<String, dynamic>.from(userData);
        updatedUserData['posts_count'] = postsData.length;
        updatedUserData['total_fires_received'] = totalFires;

        return User.fromJson(updatedUserData);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Update user profile
  Future<User?> updateUserProfile({
    required String userId,
    String? nickname,
    String? bio,
    String? avatarUrl,
    String? birthday,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (birthday != null) updateData['birthday'] = birthday;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client.update(
        table: 'users',
        data: updateData,
        filters: {'id': userId},
      );

      return User.fromJson(result);
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // Increment user's post count
  Future<bool> incrementUserPosts(String userId) async {
    try {
      // Get current user
      final user = await getUserById(userId);
      if (user == null) return false;

      // Get user's current posts count
      final postsData = await _client.select(
        table: 'posts',
        filters: {'user_id': userId},
      );
      final postsCount = postsData.length;

      // Update posts count
      await _client.update(
        table: 'users',
        data: {
          'posts_count': postsCount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': userId},
      );

      return true;
    } catch (e) {
      print('Error incrementing user posts: $e');
      return false;
    }
  }

  // Increment user's fires received count
  Future<bool> incrementUserFires(String userId) async {
    try {
      // Get current user
      final user = await getUserById(userId);
      if (user == null) return false;

      // Get all posts by this user to calculate total fires
      final postsData = await _client.select(
        table: 'posts',
        filters: {'user_id': userId},
      );

      // Calculate total fires received
      int totalFires = 0;
      for (final post in postsData) {
        totalFires += post['fires_count'] as int? ?? 0;
      }

      // Update fires count
      await _client.update(
        table: 'users',
        data: {
          'total_fires_received': totalFires,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': userId},
      );

      return true;
    } catch (e) {
      print('Error incrementing user fires: $e');
      return false;
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Get user's posts count
      final postsData = await _client.select(
        table: 'posts',
        filters: {'user_id': userId},
      );
      final postsCount = postsData.length;

      // Get user's total fires received
      int totalFires = 0;
      for (final post in postsData) {
        totalFires += post['fires_count'] as int? ?? 0;
      }

      // Get user's crushes count
      final crushesData = await _client.select(
        table: 'crushes',
        filters: {'from_user_id': userId},
      );
      final crushesCount = crushesData.length;

      // Get user's matches count
      final matchesData = await _client.select(
        table: 'matches',
        filters: {
          'user1_id': userId,
        },
      );
      final matches2Data = await _client.select(
        table: 'matches',
        filters: {
          'user2_id': userId,
        },
      );
      final matchesCount = matchesData.length + matches2Data.length;

      return {
        'posts': postsCount,
        'fires': totalFires,
        'crushes': crushesCount,
        'matches': matchesCount,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'posts': 0,
        'fires': 0,
        'crushes': 0,
        'matches': 0,
      };
    }
  }

  // Search users by nickname
  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllUsers();
      }

      final usersData = await _client.select(
        table: 'users',
        orderBy: 'created_at.desc',
      );

      // Filter users by nickname (case insensitive)
      final filteredUsers = usersData.where((userData) {
        final nickname = userData['nickname'] as String? ?? '';
        return nickname.toLowerCase().contains(query.toLowerCase());
      }).toList();

      return filteredUsers.map((data) => User.fromJson(data)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get users by creation date range
  Future<List<User>> getUsersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final usersData = await _client.select(
        table: 'users',
        filters: {
          'created_at': 'gte.${startDate.toIso8601String()}',
        },
        orderBy: 'created_at.desc',
      );

      // Filter by end date
      final filteredUsers = usersData.where((userData) {
        final createdAt = DateTime.parse(userData['created_at']);
        return createdAt.isBefore(endDate);
      }).toList();

      return filteredUsers.map((data) => User.fromJson(data)).toList();
    } catch (e) {
      print('Error getting users by date range: $e');
      return [];
    }
  }

  // Update user (alias for updateUserProfile)
  Future<User?> updateUser({
    required String userId,
    String? nickname,
    String? bio,
    String? avatarUrl,
    String? birthday,
  }) async {
    return await updateUserProfile(
      userId: userId,
      nickname: nickname,
      bio: bio,
      avatarUrl: avatarUrl,
      birthday: birthday,
    );
  }

  // Update user's online status
  Future<bool> updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _client.update(
        table: 'users',
        data: {
          'is_online': isOnline,
          'last_seen_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': userId},
      );
      return true;
    } catch (e) {
      // Fallback: schema may not have is_online/last_seen_at; retry with minimal update
      final msg = e.toString();
      if (msg.contains("Could not find the 'is_online' column") ||
          msg.contains("Could not find the 'last_seen_at' column")) {
        try {
          await _client.update(
            table: 'users',
            data: {
              'updated_at': DateTime.now().toIso8601String(),
            },
            filters: {'id': userId},
          );
          return true;
        } catch (_) {
          return false;
        }
      }
      print('Error updating online status: $e');
      return false;
    }
  }

  // Update last seen timestamp
  Future<bool> updateLastSeen(String userId) async {
    try {
      await _client.update(
        table: 'users',
        data: {
          'last_seen_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': userId},
      );
      return true;
    } catch (e) {
      print('Error updating last seen: $e');
      return false;
    }
  }
}
