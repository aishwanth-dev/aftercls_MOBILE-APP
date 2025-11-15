import 'package:campus_pulse/services/insforge_client.dart';

class DummyDataService {
  static final DummyDataService _instance = DummyDataService._();
  static DummyDataService get instance => _instance;
  DummyDataService._();

  final InsforgeClient _client = InsforgeClient.instance;

  // Create dummy users and posts
  Future<void> createDummyData() async {
    try {
      print('🎭 Creating dummy data...');

      // Create 4 dummy users
      final users = [
        {
          'email': 'alex@campus.com',
          'password': 'hello12345',
          'name': 'Alex Johnson',
          'nickname': 'alex_campus',
          'bio': 'Computer Science student who loves coding and gaming',
          'birthday': '2000-05-15',
        },
        {
          'email': 'sarah@campus.com',
          'password': 'hello12345',
          'name': 'Sarah Wilson',
          'nickname': 'sarah_student',
          'bio': 'Art major with a passion for photography and painting',
          'birthday': '2001-08-22',
        },
        {
          'email': 'mike@campus.com',
          'password': 'hello12345',
          'name': 'Mike Chen',
          'nickname': 'mike_uni',
          'bio': 'Business student and basketball player',
          'birthday': '1999-12-03',
        },
        {
          'email': 'emma@campus.com',
          'password': 'hello12345',
          'name': 'Emma Davis',
          'nickname': 'emma_college',
          'bio': 'Psychology major who loves reading and hiking',
          'birthday': '2002-03-18',
        },
      ];

      // Create users
      for (final userData in users) {
        try {
          // Sign up user
          await _client.signUp(
            email: userData['email']!,
            password: userData['password']!,
          );

          // Update profile with additional info
          await _client.setProfile(
            nickname: userData['nickname']!,
            bio: userData['bio']!,
          );

          print('✅ Created user: ${userData['name']}');
        } catch (e) {
          print('❌ Error creating user ${userData['name']}: $e');
        }
      }

      // Create posts for each user
      await _createDummyPosts();

      print('🎉 Dummy data creation completed!');
    } catch (e) {
      print('❌ Error creating dummy data: $e');
    }
  }

  Future<void> _createDummyPosts() async {
    try {
      // Get all users first
      final users = await _client.select(table: 'users');
      if (users.isEmpty) {
        print('⚠️ No users found to create posts for');
        return;
      }

      // Create 5 posts for each user
      for (final user in users) {
        final userId = user['id'];
        final userName = user['name'] ?? 'User';

        final posts = [
          {
            'user_id': userId,
            'image_url': 'https://picsum.photos/400/600?random=${userId}_1',
            'caption': 'Just had an amazing day at the library! 📚',
            'challenge_tag': null,
            'fires_count': 0,
            'created_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
            'updated_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          },
          {
            'user_id': userId,
            'image_url': 'https://picsum.photos/400/600?random=${userId}_2',
            'caption': 'Coffee break with friends ☕️',
            'challenge_tag': null,
            'fires_count': 0,
            'created_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
            'updated_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          },
          {
            'user_id': userId,
            'image_url': 'https://picsum.photos/400/600?random=${userId}_3',
            'caption': 'Beautiful sunset on campus 🌅',
            'challenge_tag': null,
            'fires_count': 0,
            'created_at': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
            'updated_at': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
          },
          {
            'user_id': userId,
            'image_url': 'https://picsum.photos/400/600?random=${userId}_4',
            'caption': 'Study session with the squad! 📖',
            'challenge_tag': null,
            'fires_count': 0,
            'created_at': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
            'updated_at': DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
          },
          {
            'user_id': userId,
            'image_url': 'https://picsum.photos/400/600?random=${userId}_5',
            'caption': 'Weekend vibes! 🎉',
            'challenge_tag': null,
            'fires_count': 0,
            'created_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
            'updated_at': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
          },
        ];

        for (final post in posts) {
          try {
            await _client.insert(table: 'posts', data: post);
            print('✅ Created post for $userName');
          } catch (e) {
            print('❌ Error creating post for $userName: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error creating posts: $e');
    }
  }

  // Clear all dummy data
  Future<void> clearDummyData() async {
    try {
      print('🧹 Clearing dummy data...');
      
      // Delete posts
      await _client.delete(table: 'posts', filters: {});
      
      // Delete users (except current user)
      final currentUser = await _client.getCurrentUser();
      if (currentUser != null) {
        await _client.delete(
          table: 'users', 
          filters: {'id': 'neq.${currentUser['user']['id']}'}
        );
      } else {
        await _client.delete(table: 'users', filters: {});
      }
      
      print('✅ Dummy data cleared!');
    } catch (e) {
      print('❌ Error clearing dummy data: $e');
    }
  }
}
