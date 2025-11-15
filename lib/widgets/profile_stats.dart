import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/models/user_rank_info.dart';
import 'package:campus_pulse/services/leaderboard_service.dart';

class ProfileStats extends StatefulWidget {
  final User user;
  final UserRankInfo? rankInfo;

  const ProfileStats({
    super.key,
    required this.user,
    this.rankInfo,
  });

  @override
  State<ProfileStats> createState() => _ProfileStatsState();
}

class _ProfileStatsState extends State<ProfileStats> {
  int? _monthlyRank;
  int? _overallRank;
  bool _isLoadingRanks = true;

  @override
  void initState() {
    super.initState();
    _loadRanks();
  }

  Future<void> _loadRanks() async {
    try {
      final monthlyRank =
          await LeaderboardService.instance.getUserMonthlyRank(widget.user.id);
      final overallRank =
          await LeaderboardService.instance.getUserOverallRank(widget.user.id);

      if (mounted) {
        setState(() {
          _monthlyRank = monthlyRank > 0 ? monthlyRank : null;
          _overallRank = overallRank > 0 ? overallRank : null;
          _isLoadingRanks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRanks = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.local_fire_department,
                label: 'Total Fires',
                value: widget.user.totalFiresReceived.toString(),
                color: theme.colorScheme.primary,
              ),
              _buildStatDivider(theme),
              _buildStatItem(
                icon: Icons.photo_library,
                label: 'Posts',
                value: widget.user.postsCount.toString(),
                color: theme.colorScheme.secondary,
              ),
              _buildStatDivider(theme),
              _buildStatItem(
                icon: Icons.local_fire_department_outlined,
                label: 'Streak',
                value: widget.user.dailyStreak.toString(),
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Ranking info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Leaderboard Position',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                _isLoadingRanks
                    ? const SizedBox(
                        height: 30,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRankItem(
                            label: 'Monthly Rank',
                            rank: _monthlyRank,
                            color: theme.colorScheme.primary,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                          _buildRankItem(
                            label: 'Overall Rank',
                            rank: _overallRank,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Achievements section
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 20,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildAchievements(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 40,
      color: theme.colorScheme.outline.withValues(alpha: 0.3),
    );
  }

  Widget _buildRankItem({
    required String label,
    required int? rank,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          rank != null ? '#$rank' : 'Unranked',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: rank != null ? color : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAchievements(ThemeData theme) {
    final achievements = <Widget>[];

    // Fire achievements
    if (widget.user.totalFiresReceived >= 100) {
      achievements.add(
          _buildAchievementBadge('🔥 Fire Master', theme.colorScheme.primary));
    } else if (widget.user.totalFiresReceived >= 50) {
      achievements.add(
          _buildAchievementBadge('🔥 Fire Starter', theme.colorScheme.primary));
    } else if (widget.user.totalFiresReceived >= 10) {
      achievements.add(
          _buildAchievementBadge('🔥 First Fires', theme.colorScheme.primary));
    }

    // Streak achievements
    if (widget.user.dailyStreak >= 30) {
      achievements.add(_buildAchievementBadge(
          '⚡ Streak Legend', theme.colorScheme.tertiary));
    } else if (widget.user.dailyStreak >= 10) {
      achievements.add(_buildAchievementBadge(
          '⚡ Streak Master', theme.colorScheme.tertiary));
    } else if (widget.user.dailyStreak >= 5) {
      achievements
          .add(_buildAchievementBadge('⚡ On Fire', theme.colorScheme.tertiary));
    }

    // Post achievements
    if (widget.user.postsCount >= 20) {
      achievements.add(_buildAchievementBadge(
          '📸 Content King', theme.colorScheme.secondary));
    } else if (widget.user.postsCount >= 10) {
      achievements.add(_buildAchievementBadge(
          '📸 Regular Poster', theme.colorScheme.secondary));
    } else if (widget.user.postsCount >= 5) {
      achievements.add(_buildAchievementBadge(
          '📸 Getting Started', theme.colorScheme.secondary));
    }

    // Ranking achievements
    if (_overallRank != null && _overallRank! <= 3) {
      achievements.add(_buildAchievementBadge('👑 Top 3', Colors.amber));
    } else if (_overallRank != null && _overallRank! <= 10) {
      achievements.add(_buildAchievementBadge('🏆 Top 10', Colors.orange));
    }

    // If no achievements, show a placeholder
    if (achievements.isEmpty) {
      achievements
          .add(_buildAchievementBadge('🌟 Getting Started', Colors.grey));
    }

    return achievements;
  }

  Widget _buildAchievementBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
