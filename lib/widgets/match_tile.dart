import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/models/match.dart';
import 'package:campus_pulse/models/message.dart';
import 'package:campus_pulse/services/message_service.dart';
import 'package:campus_pulse/theme.dart';

class MatchTile extends StatelessWidget {
  final User user;
  final Match match;
  final VoidCallback onTap;
  final Message? lastMessage;
  final String? currentUserId;

  const MatchTile({
    super.key,
    required this.user,
    required this.match,
    required this.onTap,
    this.lastMessage,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SwipzeeColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: SwipzeeColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                  backgroundColor: SwipzeeColors.accentPurple.withOpacity(0.1),
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                          (user.nickname.isNotEmpty
                              ? user.nickname.characters.first.toUpperCase()
                              : 'U'),
                          style: SwipzeeTypography.titleMedium.copyWith(
                            color: SwipzeeColors.accentPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Online indicator
                if (user.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: SwipzeeColors.mintGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SwipzeeColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // User info and last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.nickname,
                          style: SwipzeeTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: SwipzeeColors.darkGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Message timestamp
                      if (lastMessage != null)
                        Text(
                          _formatMessageTime(lastMessage!.createdAt),
                          style: SwipzeeTypography.bodySmall.copyWith(
                            color: SwipzeeColors.mediumGray,
                          ),
                        )
                      else
                        Text(
                          _formatMatchDate(match.createdAt),
                          style: SwipzeeTypography.bodySmall.copyWith(
                            color: SwipzeeColors.mediumGray,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Show orange dot for unread messages from other user
                      if (lastMessage != null &&
                          lastMessage!.senderId != currentUserId &&
                          !MessageService.instance
                              .isMessageRead(lastMessage!.id))
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: SwipzeeColors.fireOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _getMessagePreview(),
                          style: SwipzeeTypography.bodyMedium.copyWith(
                            color: lastMessage != null &&
                                    lastMessage!.senderId != currentUserId
                                ? SwipzeeColors.darkGray
                                : SwipzeeColors.mediumGray,
                            fontWeight: lastMessage != null &&
                                    lastMessage!.senderId != currentUserId
                                ? FontWeight.w600
                                : FontWeight.normal,
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

            const SizedBox(width: 12),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: SwipzeeColors.mediumGray,
            ),
          ],
        ),
      ),
    );
  }

  String _getMessagePreview() {
    if (lastMessage == null) {
      return 'You matched! Start a conversation 💬';
    }

    final isMe = lastMessage!.senderId == currentUserId;
    final preview = lastMessage!.content.length > 30
        ? '${lastMessage!.content.substring(0, 30)}...'
        : lastMessage!.content;

    if (isMe) {
      return 'Me: $preview';
    } else {
      return preview;
    }
  }

  String _formatMessageTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inSeconds > 0) {
      // Show "1m ago" for messages less than 1 minute old
      return '1m ago';
    } else {
      // Show "Just now" for very recent messages
      return 'Just now';
    }
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
