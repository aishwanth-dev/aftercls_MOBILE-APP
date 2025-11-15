import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/theme.dart';

class LeaderboardTile extends StatelessWidget {
  final User user;
  final int rank;
  final int score;
  final String scoreLabel;

  const LeaderboardTile({
    super.key,
    required this.user,
    required this.rank,
    required this.score,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
      child: Row(
        children: [
          // Rank
          Container(
            width: isMobile ? 35 : 40,
            height: isMobile ? 35 : 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getRankColor(rank),
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 11 : 13,
                ),
              ),
            ),
          ),

          SizedBox(width: isMobile ? 10 : 16),

          // Profile picture
          CircleAvatar(
            radius: isMobile ? 20 : 24,
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? Text(
                    (user.nickname.isNotEmpty
                        ? user.nickname.characters.first.toUpperCase()
                        : 'U'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  )
                : null,
          ),

          SizedBox(width: isMobile ? 10 : 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isMobile) const SizedBox(height: 4),
                if (!isMobile)
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: isMobile ? 14 : 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$score $scoreLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontSize: isMobile ? 11 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  score.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (rank <= 3)
                Icon(
                  _getRankIcon(rank),
                  color: _getRankColor(rank),
                  size: isMobile ? 16 : 20,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return SwipzeeColors.fireOrange;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }
}

// Global key for accessing context in static methods
