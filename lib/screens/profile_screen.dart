import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/models/post.dart';
import 'package:campus_pulse/models/user_rank_info.dart';
import 'package:campus_pulse/services/user_service.dart';
import 'package:campus_pulse/services/post_service.dart';
import 'package:campus_pulse/services/leaderboard_service.dart';
import 'package:campus_pulse/services/app_state_manager.dart';
import 'package:campus_pulse/widgets/profile_stats.dart';
import 'package:campus_pulse/screens/onboarding_screen.dart';
import 'package:campus_pulse/screens/post_upload_screen.dart';
import 'package:campus_pulse/auth/auth_manager.dart';
import 'package:campus_pulse/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campus_pulse/services/storage_service.dart';
import 'package:campus_pulse/services/dummy_data_service.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  List<Post> _userPosts = [];
  UserRankInfo? _rankInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Listen to state changes
    AppStateManager.instance.profileUpdateNotifier
        .addListener(_loadUserProfile);
    AppStateManager.instance.postsUpdateNotifier.addListener(_loadUserProfile);
  }

  @override
  void dispose() {
    AppStateManager.instance.profileUpdateNotifier
        .removeListener(_loadUserProfile);
    AppStateManager.instance.postsUpdateNotifier
        .removeListener(_loadUserProfile);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await DefaultAuthManager.instance.getCurrentUser();
      if (_currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Refresh user data from database to get latest stats
      final updatedUser =
          await UserService.instance.getUserById(_currentUser!.id);
      if (updatedUser != null) {
        _currentUser = updatedUser;
      }

      final posts =
          await PostService.instance.getPostsByUserId(_currentUser!.id);
      final rank =
          await LeaderboardService.instance.getUserRank(_currentUser!.id);

      if (mounted) {
        setState(() {
          _userPosts = posts;
          _rankInfo = rank > 0
              ? UserRankInfo(
                  userId: _currentUser!.id,
                  nickname: _currentUser!.nickname,
                  avatarUrl: _currentUser!.avatarUrl,
                  rank: rank,
                  points: _currentUser!
                      .totalFiresReceived, // Use actual fires received
                  period: 'daily',
                )
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _handleImageUpload() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        // Read image as bytes for cross-platform compatibility
        final bytes = await image.readAsBytes();

        final downloadUrl =
            await StorageService.instance.uploadUserProfileImage(
          imageBytes: bytes,
          userId: _currentUser!.id,
        );
        final updatedUser = _currentUser!.copyWith(avatarUrl: downloadUrl);

        await UserService.instance.updateUser(
          userId: _currentUser!.id,
          avatarUrl: downloadUrl,
        );

        if (mounted) {
          setState(() {
            _currentUser = updatedUser;
            _isLoading = false;
          });
        }

        // Notify state change
        AppStateManager.instance.notifyProfileUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile picture updated!',
              style: SwipzeeTypography.buttonMedium.copyWith(
                color: SwipzeeColors.white,
              ),
            ),
            backgroundColor: SwipzeeColors.mintGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile picture: $e',
              style: SwipzeeTypography.buttonMedium.copyWith(
                color: SwipzeeColors.white,
              ),
            ),
            backgroundColor: SwipzeeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createDummyData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Creating dummy data...'),
            ],
          ),
        ),
      );

      await DummyDataService.instance.createDummyData();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dummy data created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating dummy data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DefaultAuthManager.instance.signOut();
      // The AuthWrapper will automatically redirect to OnboardingScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const OnboardingScreen()),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.tertiary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUserProfile,
            child: CustomScrollView(
              slivers: [
                // Profile header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Header with logout button
                        Row(
                          children: [
                            Text(
                              'Profile',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _logout,
                              icon: Icon(
                                Icons.logout,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Profile picture and basic info
                        Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _handleImageUpload,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _currentUser!.avatarUrl !=
                                            null
                                        ? NetworkImage(_currentUser!.avatarUrl!)
                                        : null,
                                    backgroundColor: SwipzeeColors.accentPurple
                                        .withOpacity(0.1),
                                    child: _currentUser!.avatarUrl == null
                                        ? Text(
                                            (_currentUser!.nickname.isNotEmpty
                                                ? _currentUser!
                                                    .nickname.characters.first
                                                    .toUpperCase()
                                                : 'U'),
                                            style: SwipzeeTypography.heading3
                                                .copyWith(
                                              color: SwipzeeColors.accentPurple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _handleImageUpload,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: SwipzeeColors.accentPurple,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: SwipzeeColors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: SwipzeeColors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentUser!.nickname.isNotEmpty
                                  ? _currentUser!.nickname
                                  : 'User',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser!.email,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Stats
                        ProfileStats(
                          user: _currentUser!,
                          rankInfo: _rankInfo,
                        ),
                      ],
                    ),
                  ),
                ),

                // Posts section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          'My Posts',
                          style: SwipzeeTypography.heading4.copyWith(
                            color: SwipzeeColors.darkGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: SwipzeeColors.fireOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_userPosts.length}',
                            style: SwipzeeTypography.labelMedium.copyWith(
                              color: SwipzeeColors.fireOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        FloatingActionButton.small(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const PostUploadScreen(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: animation.drive(
                                      Tween(
                                              begin: const Offset(0.0, 1.0),
                                              end: Offset.zero)
                                          .chain(CurveTween(
                                              curve: Curves.easeInOut)),
                                    ),
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            );
                            if (result == true) {
                              _loadUserProfile(); // Instant refresh after post upload
                            }
                          },
                          backgroundColor: SwipzeeColors.fireOrange,
                          child: const Icon(
                            Icons.add,
                            color: SwipzeeColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Posts grid
                _userPosts.isEmpty
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          height: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start posting to appear in the feed!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = _userPosts[index];
                              return _buildPostCard(post, theme);
                            },
                            childCount: _userPosts.length,
                          ),
                        ),
                      ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showPostDetail(post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: (post.imageUrl.isNotEmpty)
                    ? Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.surface,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 32,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Image not\navailable',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: theme.colorScheme.surface,
                        child: const Icon(Icons.image, size: 32),
                      ),
              ),
            ),

            // Post info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.firesCount}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  if (post.challengeTag != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.challengeTag!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showPostDetail(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image
                      AspectRatio(
                        aspectRatio: 1,
                        child: (post.imageUrl.isNotEmpty)
                            ? Image.network(
                                post.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    child: const Icon(Icons.image, size: 64),
                                  );
                                },
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.surface,
                                child: const Icon(Icons.image, size: 64),
                              ),
                      ),

                      // Post details
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${post.firesCount} fires received',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const Spacer(),
                                // Delete button
                                IconButton(
                                  onPressed: () => _deletePost(post),
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  tooltip: 'Delete post',
                                ),
                              ],
                            ),
                            if (post.caption != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                post.caption!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                            if (post.challengeTag != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  post.challengeTag!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              'Posted ${_formatDate(post.createdAt)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PostService.instance.deletePost(post.id);

        if (mounted) {
          // Instant state update - rebuild UI immediately
          setState(() {
            _userPosts.removeWhere((p) => p.id == post.id);
            // Update user's post count
            if (_currentUser != null) {
              _currentUser = _currentUser!.copyWith(
                postsCount: (_currentUser!.postsCount > 0
                    ? _currentUser!.postsCount - 1
                    : 0),
              );
            }
          });

          Navigator.of(context).pop(); // Close the modal

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
