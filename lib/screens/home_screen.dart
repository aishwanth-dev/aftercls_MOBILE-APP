import 'package:flutter/material.dart';
import 'package:campus_pulse/models/post.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/services/post_service.dart';
import 'package:campus_pulse/services/user_service.dart';
import 'package:campus_pulse/services/app_state_manager.dart';
import 'package:campus_pulse/screens/leaderboard_screen.dart';
import 'package:campus_pulse/widgets/swipe_card.dart';
import 'package:campus_pulse/theme.dart';
import 'package:campus_pulse/auth/auth_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _posts = [];
  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Listen to state changes
    AppStateManager.instance.postsUpdateNotifier.addListener(_refreshPosts);
  }

  @override
  void dispose() {
    AppStateManager.instance.postsUpdateNotifier.removeListener(_refreshPosts);
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Get current user
      _currentUser = await DefaultAuthManager.instance.getCurrentUser();

      if (_currentUser != null) {
        // Get posts for swiping (excluding own posts and already rated posts)
        final posts =
            await PostService.instance.getPostsForSwipe(_currentUser!.id);
        final users = await UserService.instance.getAllUsers();

        if (mounted) {
          setState(() {
            _posts = posts;
            _users = users;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          backgroundColor: SwipzeeColors.error,
        ),
      );
    }
  }

  Future<void> _handleSwipe(String postId, bool isFire) async {
    try {
      if (_currentUser != null) {
        await PostService.instance.ratePost(
          postId: postId,
          userId: _currentUser!.id,
          isFire: isFire,
        );

        // Notify state change for instant leaderboard update
        AppStateManager.instance.notifyLeaderboardUpdated();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFire ? Icons.local_fire_department : Icons.close,
                  color: SwipzeeColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isFire ? 'Fired! 🔥' : 'Passed',
                  style: SwipzeeTypography.buttonMedium.copyWith(
                    color: SwipzeeColors.white,
                  ),
                ),
              ],
            ),
            backgroundColor:
                isFire ? SwipzeeColors.fireOrange : SwipzeeColors.mediumGray,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rate post: $e'),
          backgroundColor: SwipzeeColors.error,
        ),
      );
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: SwipzeeColors.lightGray,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: SwipzeeColors.fireOrange,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading amazing content...',
                style: SwipzeeTypography.bodyLarge.copyWith(
                  color: SwipzeeColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SwipzeeColors.lightGray,
      appBar: AppBar(
        title: Text(
          'Swipzee',
          style: SwipzeeTypography.heading3.copyWith(
            color: SwipzeeColors.darkGray,
          ),
        ),
        backgroundColor: SwipzeeColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.leaderboard,
            color: SwipzeeColors.fireOrange,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LeaderboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.easeInOut)),
                    ),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _posts.isNotEmpty
            ? SwipeCardStack(
                posts: _posts,
                users: _users,
                onSwipe: _handleSwipe,
                onSwipeLeft: () {
                  // Optional: Add haptic feedback
                },
                onSwipeRight: () {
                  // Optional: Add haptic feedback
                },
              )
            : _buildNoPostsView(),
      ),
    );
  }

  Widget _buildNoPostsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: SwipzeeColors.mediumGray,
            ),
            const SizedBox(height: 24),
            Text(
              'No more posts to swipe!',
              style: SwipzeeTypography.heading3.copyWith(
                color: SwipzeeColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Check back later for new content or refresh to see if there are new posts available.',
              style: SwipzeeTypography.bodyLarge.copyWith(
                color: SwipzeeColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
              style: SwipzeeStyles.fireButtonStyle,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Refresh',
                style: SwipzeeTypography.buttonMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
