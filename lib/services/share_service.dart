import 'package:campus_pulse/models/shared_post.dart';
import 'package:campus_pulse/services/insforge_client.dart';
import 'package:flutter/foundation.dart';

class ShareService {
  // Singleton pattern
  static final ShareService _instance = ShareService._internal();
  static ShareService get instance => _instance;
  ShareService._internal();

  final InsforgeClient _insforgeClient = InsforgeClient.instance;
  final String _table = 'shared_posts';

  Future<List<SharedPost>> getAllSharedPosts() async {
    try {
      // Get current user to include their reactions
      final currentUser = await _insforgeClient.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      final userId = currentUser['user']['id'];
      print('Fetching posts for user: $userId');

      // Fetch posts with user's reactions in a single query using join
      // Filter out expired posts (where expires_at > current time)
      final response = await _insforgeClient.select(
        table: _table,
        filters: {
          'expires_at': 'gt.now()', // Only get posts that haven't expired
        },
        orderBy: 'created_at.desc',
      );
      
      print('Fetched ${response.length} posts from database');
      
      // Get user's reactions for these posts
      final posts = response.map((json) {
        // Create post from JSON but don't set userReaction yet
        final post = SharedPost.fromJson(json);
        return post;
      }).toList();
      
      // Fetch user's reactions for these posts in parallel for better performance
      if (posts.isNotEmpty) {
        print('Fetching reactions for ${posts.length} posts');
        final reactionFutures = posts.map((post) async {
          final userReaction = await _getUserReactionForPost(post.id, userId);
          post.userReaction = userReaction;
        });
        await Future.wait(reactionFutures);
        print('Finished fetching reactions');
      }
      
      // Log the final state
      for (final post in posts) {
        print('Post ${post.id} - User reaction: "${post.userReaction}"');
      }
      
      return posts;
    } catch (e) {
      print('Error fetching shared posts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserReactions(String userId) async {
    try {
      // Get user reactions but only for non-expired posts
      final response = await _insforgeClient.select(
        table: 'shared_post_reactions',
        filters: {'user_id': userId},
      );

      // Filter out reactions for expired posts
      final allReactions = response;

      // Get current active posts to filter reactions
      final activePostsResponse = await _insforgeClient.select(
        table: _table,
        filters: {
          'expires_at': 'gt.now()',
        },
      );

      final activePostIds = activePostsResponse
          .map((post) => post['id'] as String)
          .toSet();

      return allReactions
          .where((reaction) => activePostIds.contains(reaction['post_id']))
          .toList();
    } catch (e) {
      print('Error getting user reactions: $e');
      return [];
    }
  }

  Future<String> _getUserReactionForPost(String postId, String userId) async {
    try {
      print('Fetching user reaction for post $postId and user $userId');
      final response = await _insforgeClient.select(
        table: 'shared_post_reactions',
        filters: {
          'post_id': 'eq.$postId',
          'user_id': 'eq.$userId',
        },
      );
      
      print('User reaction response: $response');
      if (response.isNotEmpty) {
        final rawReaction = response.first['reaction'] ?? '';
        // Normalize legacy emoji values to canonical type strings
        final emojiToType = {
          '❤️': 'heart',
          '😂': 'laugh',
          '🥵': 'hot',
          '💔': 'broken_heart',
        };
        final reactionType = emojiToType[rawReaction] ?? rawReaction;
        print('Found user reaction (normalized): $reactionType');
        return reactionType;
      }
      print('No user reaction found');
      return '';
    } catch (e) {
      print('Error fetching user reaction: $e');
      return '';
    }
  }

  Future<void> createSharedPost({required String text}) async {
    try {
      final currentUser = await _insforgeClient.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      final userId = currentUser['user']['id'];

      await _insforgeClient.insert(
        table: _table,
        data: {
          'text': text,
          'user_id': userId,
        },
      );
    } catch (e) {
      print('Error creating shared post: $e');
    }
  }

  Future<void> updatePostReaction(String postId, String reaction, bool reacted) async {
    try {
      // Use the edge function to handle reactions properly
      final response = await _insforgeClient.invokeEdgeFunction(
        'handle-reaction',
        body: {
          'postId': postId,
          'reactionType': reaction,
        },
      );

      if (response['error'] != null) {
        throw Exception('Failed to update reaction: ${response['error']}');
      }

      print('Reaction updated: ${response['data']}');
    } catch (e) {
      print('Error updating post reaction: $e');
      rethrow; // Re-throw the error so the UI can handle it
    }
  }
}
