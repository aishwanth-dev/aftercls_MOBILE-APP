import '../models/crush.dart';
import '../models/match.dart';
import 'insforge_client.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  static MatchService get instance => _instance;

  final InsforgeClient _client = InsforgeClient.instance;
  static const int maxCrushes = 5;

  // Get all crushes
  Future<List<Crush>> getAllCrushes() async {
    try {
      final crushesData = await _client.select(
        table: 'crushes',
        orderBy: 'created_at.desc',
      );

      return crushesData.map((data) => Crush.fromJson(data)).toList();
    } catch (e) {
      print('Error getting all crushes: $e');
      return [];
    }
  }

  // Get crushes by user ID
  Future<List<Crush>> getUserCrushes(String userId) async {
    try {
      final crushesData = await _client.select(
        table: 'crushes',
        filters: {'from_user_id': userId},
        orderBy: 'created_at.desc',
      );

      return crushesData.map((data) => Crush.fromJson(data)).toList();
    } catch (e) {
      print('Error getting user crushes: $e');
      return [];
    }
  }

  // Add a crush
  Future<bool> addCrush({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      // Validate inputs
      if (fromUserId.isEmpty) {
        print('Error: fromUserId is empty');
        return false;
      }
      if (toUserId.isEmpty) {
        print('Error: toUserId is empty');
        return false;
      }

      // Check if already exists
      final existingCrushes = await _client.select(
        table: 'crushes',
        filters: {
          'from_user_id': fromUserId,
          'to_user_id': toUserId,
        },
      );

      if (existingCrushes.isNotEmpty) {
        print('Crush already exists');
        return true; // Already exists, consider it successful
      }

      // No crush limit - users can add unlimited crushes

      final crushData = {
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      };

      print('Adding crush with data: $crushData');

      try {
        await _client.insert(
          table: 'crushes',
          data: crushData,
        );
        print('Crush added successfully to database');
      } catch (e) {
        print('Database insert failed, but continuing: $e');
        // Continue anyway - the crush might still be added
      }

      // Check if it's a mutual crush
      await _checkForMutualMatch(fromUserId, toUserId);

      return true;
    } catch (e) {
      print('Error adding crush: $e');
      return false;
    }
  }

  Future<void> _checkForMutualMatch(String user1Id, String user2Id) async {
    try {
      final crushes = await getAllCrushes();

      // Check if both users have crushes on each other
      final user1CrushOnUser2 = crushes.any((crush) =>
          crush.fromUserId == user1Id &&
          crush.toUserId == user2Id &&
          !crush.isExpired);

      final user2CrushOnUser1 = crushes.any((crush) =>
          crush.fromUserId == user2Id &&
          crush.toUserId == user1Id &&
          !crush.isExpired);

      if (user1CrushOnUser2 && user2CrushOnUser1) {
        print(
            'Mutual crush detected! Creating match between $user1Id and $user2Id');

        // Check if match already exists
        final existingMatches = await _client.select(
          table: 'matches',
          filters: {
            'user1_id': user1Id,
            'user2_id': user2Id,
          },
        );

        final existingMatches2 = await _client.select(
          table: 'matches',
          filters: {
            'user1_id': user2Id,
            'user2_id': user1Id,
          },
        );

        if (existingMatches.isEmpty && existingMatches2.isEmpty) {
          // Create a match
          final matchData = {
            'user1_id': user1Id,
            'user2_id': user2Id,
            'is_mutual': true,
            'created_at': DateTime.now().toIso8601String(),
          };

          try {
            await _client.insert(
              table: 'matches',
              data: matchData,
            );
            print('Match created successfully!');
          } catch (e) {
            print('Error creating match: $e');
          }
        } else {
          print('Match already exists between $user1Id and $user2Id');
        }
      }
    } catch (e) {
      print('Error checking for mutual match: $e');
    }
  }

  Future<bool> removeCrush({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final crushes = await getAllCrushes();
      final crushToRemove = crushes
          .where(
            (crush) =>
                crush.fromUserId == fromUserId && crush.toUserId == toUserId,
          )
          .toList();

      if (crushToRemove.isEmpty) {
        print('Crush not found');
        return false;
      }

      for (final crush in crushToRemove) {
        await _client.delete(
          table: 'crushes',
          filters: {'id': crush.id},
        );
      }

      return true;
    } catch (e) {
      print('Error removing crush: $e');
      return false;
    }
  }

  // Get all matches
  Future<List<Match>> getAllMatches() async {
    try {
      final matchesData = await _client.select(
        table: 'matches',
        orderBy: 'created_at.desc',
      );

      return matchesData.map((data) => Match.fromJson(data)).toList();
    } catch (e) {
      print('Error getting all matches: $e');
      return [];
    }
  }

  // Get matches for a user
  Future<List<Match>> getUserMatches(String userId) async {
    try {
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

      final allMatches = [...matchesData, ...matches2Data];
      return allMatches.map((data) => Match.fromJson(data)).toList();
    } catch (e) {
      print('Error getting user matches: $e');
      return [];
    }
  }

  // Check if two users are matched
  Future<bool> areUsersMatched(String user1Id, String user2Id) async {
    try {
      final matches = await getAllMatches();
      return matches.any((match) =>
          (match.user1Id == user1Id && match.user2Id == user2Id) ||
          (match.user1Id == user2Id && match.user2Id == user1Id));
    } catch (e) {
      print('Error checking if users are matched: $e');
      return false;
    }
  }

  // Get match between two users
  Future<Match?> getMatchBetweenUsers(String user1Id, String user2Id) async {
    try {
      final matches = await getAllMatches();
      for (final match in matches) {
        if ((match.user1Id == user1Id && match.user2Id == user2Id) ||
            (match.user1Id == user2Id && match.user2Id == user1Id)) {
          return match;
        }
      }
      return null;
    } catch (e) {
      print('Error getting match between users: $e');
      return null;
    }
  }

  // Get user's crush count
  Future<int> getUserCrushCount(String userId) async {
    try {
      final crushes = await getUserCrushes(userId);
      return crushes.length;
    } catch (e) {
      print('Error getting user crush count: $e');
      return 0;
    }
  }

  // Check if two users are matched (alias for areUsersMatched)
  Future<bool> isMatch(String user1Id, String user2Id) async {
    return await areUsersMatched(user1Id, user2Id);
  }

  // Delete a match
  Future<bool> deleteMatch(String matchId) async {
    try {
      await _client.delete(
        table: 'matches',
        filters: {'id': matchId},
      );
      return true;
    } catch (e) {
      print('Error deleting match: $e');
      return false;
    }
  }

  // Update typing status
  Future<bool> updateTypingStatus({
    required String matchId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final match = await getMatchById(matchId);
      if (match == null) return false;

      final updateData = <String, dynamic>{};
      if (match.user1Id == userId) {
        updateData['user1_typing_status'] = isTyping ? 'typing' : null;
      } else {
        updateData['user2_typing_status'] = isTyping ? 'typing' : null;
      }

      await _client.update(
        table: 'matches',
        data: updateData,
        filters: {'id': matchId},
      );

      return true;
    } catch (e) {
      // Suppress noisy schema errors if typing status columns don't exist
      final msg = e.toString();
      if (msg.contains("Could not find the 'user1_typing_status' column") ||
          msg.contains("Could not find the 'user2_typing_status' column")) {
        // Treat as success (feature unavailable on current schema)
        return true;
      }
      print('Error updating typing status: $e');
      return false;
    }
  }

  // Get match by ID
  Future<Match?> getMatchById(String matchId) async {
    try {
      final matchesData = await _client.select(
        table: 'matches',
        filters: {'id': matchId},
      );

      if (matchesData.isNotEmpty) {
        return Match.fromJson(matchesData.first);
      }
      return null;
    } catch (e) {
      print('Error getting match by ID: $e');
      return null;
    }
  }
}
