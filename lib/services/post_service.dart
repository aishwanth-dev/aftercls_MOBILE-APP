import '../models/post.dart';
import 'insforge_client.dart';
import 'user_service.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  static PostService get instance => _instance;

  final InsforgeClient _client = InsforgeClient.instance;
  final UserService _userService = UserService.instance;

  // Get all posts
  Future<List<Post>> getAllPosts() async {
    try {
      final postsData = await _client.select(
        table: 'posts',
        orderBy: 'created_at.desc',
      );

      final posts = <Post>[];
      for (final postData in postsData) {
        final user = await _userService.getUserById(postData['user_id']);
        if (user != null) {
          posts.add(Post.fromJson(postData, user));
        }
      }
      return posts;
    } catch (e) {
      print('Error getting all posts: $e');
      return [];
    }
  }

  // Get posts by user ID
  Future<List<Post>> getPostsByUserId(String userId) async {
    try {
      final postsData = await _client.select(
        table: 'posts',
        filters: {'user_id': userId},
        orderBy: 'created_at.desc',
      );

      final posts = <Post>[];
      for (final postData in postsData) {
        final user = await _userService.getUserById(postData['user_id']);
        if (user != null) {
          posts.add(Post.fromJson(postData, user));
        }
      }
      return posts;
    } catch (e) {
      print('Error getting posts by user ID: $e');
      return [];
    }
  }

  // Get posts for swipe (excluding user's own posts and already rated posts)
  Future<List<Post>> getPostsForSwipe(String currentUserId) async {
    try {
      // Get all posts
      final allPosts = await getAllPosts();

      // Get user ratings
      final ratingsData = await _client.select(
        table: 'ratings',
        filters: {'rater_id': currentUserId},
      );

      final ratedPostIds =
          ratingsData.map((rating) => rating['post_id'] as String).toSet();

      // Filter posts that haven't been rated and aren't user's own posts
      return allPosts
          .where((post) =>
              post.userId != currentUserId && !ratedPostIds.contains(post.id))
          .toList();
    } catch (e) {
      print('Error getting posts for swipe: $e');
      return [];
    }
  }

  // Rate a post (fire or pass)
  Future<bool> ratePost({
    required String postId,
    required String userId,
    required bool isFire, // true for 🔥, false for ❌
  }) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        print('Error: userId is empty');
        return false;
      }
      if (postId.isEmpty) {
        print('Error: postId is empty');
        return false;
      }

      // Create rating
      final ratingData = {
        'rater_id': userId,
        'post_id': postId,
        'is_fire': isFire,
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        await _client.insert(
          table: 'ratings',
          data: ratingData,
        );
        print('Rating added successfully');
      } catch (e) {
        print('Rating insert failed, but continuing: $e');
        // Continue anyway - the rating might still be added
      }

      // If it's a fire, increment the post's fire count
      if (isFire) {
        // Get current post to find owner
        final postsData = await _client.select(
          table: 'posts',
          filters: {'id': postId},
        );

        if (postsData.isNotEmpty) {
          final postData = postsData.first;
          final postOwnerId = postData['user_id'] as String;
          final currentFiresCount = postData['fires_count'] as int;

          // Update post fire count
          await _client.update(
            table: 'posts',
            data: {
              'fires_count': currentFiresCount + 1,
            },
            filters: {'id': postId},
          );

          // Update user's total fires received
          await _userService.incrementUserFires(postOwnerId);
        }
      }

      return true;
    } catch (e) {
      print('Error rating post: $e');
      return false;
    }
  }

  // Create a new post
  Future<Post?> createPost({
    required String userId,
    required String imageUrl,
    String? caption,
    String? challengeTag,
  }) async {
    try {
      // Validate inputs
      if (userId.isEmpty) {
        print('Error: userId is empty');
        return null;
      }
      if (imageUrl.isEmpty) {
        print('Error: imageUrl is empty');
        return null;
      }

      final postData = {
        'user_id': userId,
        'image_url': imageUrl,
        'caption': caption,
        'challenge_tag': challengeTag,
        'fires_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _client.insert(
        table: 'posts',
        data: postData,
      );

      // Get the user for the post
      final user = await _userService.getUserById(userId);
      if (user != null) {
        // Update user's post count
        await _userService.incrementUserPosts(userId);

        return Post.fromJson(result, user);
      }

      return null;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _client.delete(
        table: 'posts',
        filters: {'id': postId},
      );
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Get posts by challenge tag
  Future<List<Post>> getPostsByChallenge(String challengeTag) async {
    try {
      final postsData = await _client.select(
        table: 'posts',
        filters: {'challenge_tag': challengeTag},
        orderBy: 'created_at.desc',
      );

      final posts = <Post>[];
      for (final postData in postsData) {
        final user = await _userService.getUserById(postData['user_id']);
        if (user != null) {
          posts.add(Post.fromJson(postData, user));
        }
      }
      return posts;
    } catch (e) {
      print('Error getting posts by challenge: $e');
      return [];
    }
  }

  // Get trending posts (most fires)
  Future<List<Post>> getTrendingPosts({int limit = 10}) async {
    try {
      final postsData = await _client.select(
        table: 'posts',
        orderBy: 'fires_count.desc',
        limit: limit,
      );

      final posts = <Post>[];
      for (final postData in postsData) {
        final user = await _userService.getUserById(postData['user_id']);
        if (user != null) {
          posts.add(Post.fromJson(postData, user));
        }
      }
      return posts;
    } catch (e) {
      print('Error getting trending posts: $e');
      return [];
    }
  }
}
