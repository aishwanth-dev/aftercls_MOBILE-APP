import '../models/leaderboard_user.dart';
import '../models/leaderboard_post.dart';
import '../models/user.dart';
import 'insforge_client.dart';

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  static LeaderboardService get instance => _instance;

  final InsforgeClient _client = InsforgeClient.instance;

  // Get daily top users (by fires received today)
  Future<List<LeaderboardUser>> getDailyTopUsers({int limit = 10}) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get all users
      final users = await _client.select(
        table: 'users',
      );

      // Get today's ratings
      final todayRatingsData = await _client.select(
        table: 'ratings',
        filters: {
          'created_at': 'gte.${startOfDay.toIso8601String()}',
          'is_fire': 'eq.true',
        },
      );

      final Map<String, int> userToDailyFires = {};
      for (final rating in todayRatingsData) {
        final postId = rating['post_id'] as String?;
        if (postId == null) continue;

        // Get post owner
        final postsData = await _client.select(
          table: 'posts',
          filters: {'id': 'eq.$postId'},
        );

        if (postsData.isNotEmpty) {
          final ownerId = postsData.first['user_id'] as String?;
          if (ownerId != null) {
            userToDailyFires[ownerId] = (userToDailyFires[ownerId] ?? 0) + 1;
          }
        }
      }

      final leaderboardUsers = <LeaderboardUser>[];
      for (final user in users) {
        final fires = userToDailyFires[user['id']] ?? 0;
        if (fires > 0) {
          final userObj = User.fromJson(user);
          leaderboardUsers.add(LeaderboardUser(
            id: user['id'],
            nickname: user['nickname'] ?? 'Unknown',
            avatarUrl: user['avatar_url'],
            points: fires,
            rank: 0, // Will be set after sorting
            user: userObj,
          ));
        }
      }

      // Sort by points descending
      leaderboardUsers.sort((a, b) => b.points.compareTo(a.points));

      // Set ranks
      for (int i = 0; i < leaderboardUsers.length; i++) {
        leaderboardUsers[i] = leaderboardUsers[i].copyWith(rank: i + 1);
      }

      return leaderboardUsers.take(limit).toList();
    } catch (e) {
      print('Error getting daily top users: $e');
      return [];
    }
  }

  // Get weekly top users (by fires received this week)
  Future<List<LeaderboardUser>> getWeeklyTopUsers({int limit = 10}) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      // Get all users
      final users = await _client.select(
        table: 'users',
      );

      // Get this week's ratings
      final weekRatingsData = await _client.select(
        table: 'ratings',
        filters: {
          'created_at': 'gte.${startOfWeekDay.toIso8601String()}',
          'is_fire': 'eq.true',
        },
      );

      final Map<String, int> userToWeeklyFires = {};
      for (final rating in weekRatingsData) {
        final postId = rating['post_id'] as String?;
        if (postId == null) continue;

        // Get post owner
        final postsData = await _client.select(
          table: 'posts',
          filters: {'id': 'eq.$postId'},
        );

        if (postsData.isNotEmpty) {
          final ownerId = postsData.first['user_id'] as String?;
          if (ownerId != null) {
            userToWeeklyFires[ownerId] = (userToWeeklyFires[ownerId] ?? 0) + 1;
          }
        }
      }

      final leaderboardUsers = <LeaderboardUser>[];
      for (final user in users) {
        final fires = userToWeeklyFires[user['id']] ?? 0;
        if (fires > 0) {
          final userObj = User.fromJson(user);
          leaderboardUsers.add(LeaderboardUser(
            id: user['id'],
            nickname: user['nickname'] ?? 'Unknown',
            avatarUrl: user['avatar_url'],
            points: fires,
            rank: 0, // Will be set after sorting
            user: userObj,
          ));
        }
      }

      // Sort by points descending
      leaderboardUsers.sort((a, b) => b.points.compareTo(a.points));

      // Set ranks
      for (int i = 0; i < leaderboardUsers.length; i++) {
        leaderboardUsers[i] = leaderboardUsers[i].copyWith(rank: i + 1);
      }

      return leaderboardUsers.take(limit).toList();
    } catch (e) {
      print('Error getting weekly top users: $e');
      return [];
    }
  }

  // Get all-time top users (by total fires received)
  Future<List<LeaderboardUser>> getAllTimeTopUsers({int limit = 0}) async {
    try {
      // Get all users
      final users = await _client.select(
        table: 'users',
      );

      // Get all posts with their fire counts
      final postsData = await _client.select(
        table: 'posts',
      );

      final Map<String, int> userToTotalFires = {};
      for (final post in postsData) {
        final ownerId = post['user_id'] as String?;
        final firesCount = post['fires_count'] as int? ?? 0;
        if (ownerId != null) {
          userToTotalFires[ownerId] =
              (userToTotalFires[ownerId] ?? 0) + firesCount;
        }
      }

      final leaderboardUsers = <LeaderboardUser>[];
      for (final user in users) {
        final fires = userToTotalFires[user['id']] ?? 0;
        if (fires > 0) {
          final userObj = User.fromJson(user);
          leaderboardUsers.add(LeaderboardUser(
            id: user['id'],
            nickname: user['nickname'] ?? 'Unknown',
            avatarUrl: user['avatar_url'],
            points: fires,
            rank: 0, // Will be set after sorting
            user: userObj,
          ));
        }
      }

      // Sort by points descending
      leaderboardUsers.sort((a, b) => b.points.compareTo(a.points));

      // Set ranks
      for (int i = 0; i < leaderboardUsers.length; i++) {
        leaderboardUsers[i] = leaderboardUsers[i].copyWith(rank: i + 1);
      }

      // Return all users if limit is 0, otherwise limit the results
      return limit == 0
          ? leaderboardUsers
          : leaderboardUsers.take(limit).toList();
    } catch (e) {
      print('Error getting all-time top users: $e');
      return [];
    }
  }

  // Get top posts by fires
  Future<List<LeaderboardPost>> getTopPosts({int limit = 10}) async {
    try {
      final postsData = await _client.select(
        table: 'posts',
        orderBy: 'fires_count.desc',
        limit: limit,
      );

      final leaderboardPosts = <LeaderboardPost>[];
      for (int i = 0; i < postsData.length; i++) {
        final post = postsData[i];

        // Get user data for this post
        final usersData = await _client.select(
          table: 'users',
          filters: {'id': post['user_id']},
        );

        User user;
        if (usersData.isNotEmpty) {
          user = User.fromJson(usersData.first);
        } else {
          user = User(
            id: post['user_id'],
            email: '',
            nickname: 'Unknown',
            bio: '',
            avatarUrl: null,
            birthday: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        leaderboardPosts.add(LeaderboardPost(
          id: post['id'],
          imageUrl: post['image_url'],
          caption: post['caption'],
          firesCount: post['fires_count'] as int? ?? 0,
          rank: i + 1,
          userId: post['user_id'],
          user: user,
        ));
      }

      return leaderboardPosts;
    } catch (e) {
      print('Error getting top posts: $e');
      return [];
    }
  }

  // Get challenge leaderboard
  Future<List<LeaderboardUser>> getChallengeLeaderboard({
    required String challengeTag,
    int limit = 10,
  }) async {
    try {
      // Get posts for this challenge
      final postsData = await _client.select(
        table: 'posts',
        filters: {'challenge_tag': 'eq.$challengeTag'},
      );

      final Map<String, int> userToChallengeFires = {};
      for (final post in postsData) {
        final ownerId = post['user_id'] as String?;
        final firesCount = post['fires_count'] as int? ?? 0;
        if (ownerId != null) {
          userToChallengeFires[ownerId] =
              (userToChallengeFires[ownerId] ?? 0) + firesCount;
        }
      }

      // Get users for this challenge
      final users = await _client.select(
        table: 'users',
      );

      final leaderboardUsers = <LeaderboardUser>[];
      for (final user in users) {
        final fires = userToChallengeFires[user['id']] ?? 0;
        if (fires > 0) {
          final userObj = User.fromJson(user);
          leaderboardUsers.add(LeaderboardUser(
            id: user['id'],
            nickname: user['nickname'] ?? 'Unknown',
            avatarUrl: user['avatar_url'],
            points: fires,
            rank: 0, // Will be set after sorting
            user: userObj,
          ));
        }
      }

      // Sort by points descending
      leaderboardUsers.sort((a, b) => b.points.compareTo(a.points));

      // Set ranks
      for (int i = 0; i < leaderboardUsers.length; i++) {
        leaderboardUsers[i] = leaderboardUsers[i].copyWith(rank: i + 1);
      }

      return leaderboardUsers.take(limit).toList();
    } catch (e) {
      print('Error getting challenge leaderboard: $e');
      return [];
    }
  }

  // Get user's rank in daily leaderboard
  Future<int> getUserRank(String userId) async {
    try {
      final dailyUsers = await getDailyTopUsers(limit: 1000);
      for (int i = 0; i < dailyUsers.length; i++) {
        if (dailyUsers[i].id == userId) {
          return i + 1;
        }
      }
      return 0; // User not found in leaderboard
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  // Get user's daily rank
  Future<int> getUserDailyRank(String userId) async {
    return await getUserRank(userId);
  }

  // Get user's weekly rank
  Future<int> getUserWeeklyRank(String userId) async {
    try {
      final weeklyUsers = await getWeeklyTopUsers(limit: 1000);
      for (int i = 0; i < weeklyUsers.length; i++) {
        if (weeklyUsers[i].id == userId) {
          return i + 1;
        }
      }
      return 0; // User not found in leaderboard
    } catch (e) {
      print('Error getting user weekly rank: $e');
      return 0;
    }
  }

  // Get monthly top users
  Future<List<LeaderboardUser>> getMonthlyTopUsers({int limit = 100}) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get all users
      final users = await _client.select(
        table: 'users',
      );

      // Get this month's ratings
      final monthRatingsData = await _client.select(
        table: 'ratings',
        filters: {
          'created_at': 'gte.${startOfMonth.toIso8601String()}',
          'is_fire': 'eq.true',
        },
      );

      final Map<String, int> userToMonthlyFires = {};
      for (final rating in monthRatingsData) {
        final postId = rating['post_id'] as String?;
        if (postId == null) continue;

        // Get post owner
        final postsData = await _client.select(
          table: 'posts',
          filters: {'id': 'eq.$postId'},
        );

        if (postsData.isNotEmpty) {
          final ownerId = postsData.first['user_id'] as String?;
          if (ownerId != null) {
            userToMonthlyFires[ownerId] =
                (userToMonthlyFires[ownerId] ?? 0) + 1;
          }
        }
      }

      final leaderboardUsers = <LeaderboardUser>[];
      for (final user in users) {
        final fires = userToMonthlyFires[user['id']] ?? 0;
        if (fires > 0) {
          final userObj = User.fromJson(user);
          leaderboardUsers.add(LeaderboardUser(
            id: user['id'],
            nickname: user['nickname'] ?? 'Unknown',
            avatarUrl: user['avatar_url'],
            points: fires,
            rank: 0,
            user: userObj,
          ));
        }
      }

      // Sort by points descending
      leaderboardUsers.sort((a, b) => b.points.compareTo(a.points));

      // Set ranks
      for (int i = 0; i < leaderboardUsers.length; i++) {
        leaderboardUsers[i] = leaderboardUsers[i].copyWith(rank: i + 1);
      }

      return leaderboardUsers.take(limit).toList();
    } catch (e) {
      print('Error getting monthly top users: $e');
      return [];
    }
  }

  // Get user's monthly rank
  Future<int> getUserMonthlyRank(String userId) async {
    try {
      final monthlyUsers = await getMonthlyTopUsers(limit: 1000);
      for (int i = 0; i < monthlyUsers.length; i++) {
        if (monthlyUsers[i].id == userId) {
          return i + 1;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting user monthly rank: $e');
      return 0;
    }
  }

  // Get user's overall rank
  Future<int> getUserOverallRank(String userId) async {
    try {
      final overallUsers =
          await getAllTimeTopUsers(); // No limit - get all users
      for (int i = 0; i < overallUsers.length; i++) {
        if (overallUsers[i].id == userId) {
          return i + 1;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting user overall rank: $e');
      return 0;
    }
  }

  // Get challenge top posts (alias for getTopPosts)
  Future<List<LeaderboardPost>> getChallengeTopPosts({int limit = 10}) async {
    return await getTopPosts(limit: limit);
  }

  // Update user points when they receive a fire
  Future<void> updateUserPoints(String userId) async {
    try {
      // Get all posts by the user
      final userPosts = await _client.select(
        table: 'posts',
        filters: {'user_id': userId},
      );

      // Calculate total fires received
      int totalFires = 0;
      for (final post in userPosts) {
        totalFires += post['fires_count'] as int? ?? 0;
      }

      // Update user's points in the database
      await _client.update(
        table: 'users',
        data: {
          'total_fires_received': totalFires,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': userId},
      );

      print('Updated points for user $userId: $totalFires fires');
    } catch (e) {
      print('Error updating user points: $e');
    }
  }
}
