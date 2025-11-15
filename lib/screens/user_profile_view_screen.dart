import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/models/user_rank_info.dart';
import 'package:campus_pulse/services/user_service.dart';
import 'package:campus_pulse/services/leaderboard_service.dart';
import 'package:campus_pulse/widgets/profile_stats.dart';
import 'package:campus_pulse/theme.dart';

class UserProfileViewScreen extends StatefulWidget {
  final User user;

  const UserProfileViewScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  User? _user;
  UserRankInfo? _rankInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Refresh user data from database to get latest stats
      final updatedUser =
          await UserService.instance.getUserById(widget.user.id);
      if (updatedUser != null) {
        _user = updatedUser;
      } else {
        _user = widget.user;
      }

      final rank = await LeaderboardService.instance.getUserRank(_user!.id);

      if (mounted) {
        setState(() {
          _rankInfo = rank > 0
              ? UserRankInfo(
                  userId: _user!.id,
                  nickname: _user!.nickname,
                  avatarUrl: _user!.avatarUrl,
                  rank: rank,
                  points: _user!.totalFiresReceived,
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'User not found',
            style: theme.textTheme.titleLarge,
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
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Profile',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                pinned: true,
              ),

              // Profile content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _user!.avatarUrl != null
                            ? NetworkImage(_user!.avatarUrl!)
                            : null,
                        backgroundColor:
                            SwipzeeColors.accentPurple.withValues(alpha: 0.1),
                        child: _user!.avatarUrl == null
                            ? Text(
                                (_user!.nickname.isNotEmpty
                                    ? _user!.nickname.characters.first
                                        .toUpperCase()
                                    : 'U'),
                                style: SwipzeeTypography.heading3.copyWith(
                                  color: SwipzeeColors.accentPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // User name
                      Text(
                        _user!.nickname,
                        style: SwipzeeTypography.heading3.copyWith(
                          color: SwipzeeColors.darkGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bio
                      if (_user!.bio?.isNotEmpty ?? false)
                        Text(
                          _user!.bio!,
                          style: SwipzeeTypography.bodyMedium.copyWith(
                            color: SwipzeeColors.mediumGray,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 24),

                      // Stats card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: SwipzeeColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Stats row
                            ProfileStats(
                              user: _user!,
                              rankInfo: _rankInfo,
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
}
