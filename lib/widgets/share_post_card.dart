import 'package:flutter/material.dart';
import 'package:campus_pulse/widgets/reaction_button.dart';
import 'package:campus_pulse/models/shared_post.dart';
import 'package:campus_pulse/services/share_service.dart';
import 'package:campus_pulse/theme.dart';

class SharePostCard extends StatefulWidget {
  final SharedPost post;

  const SharePostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  _SharePostCardState createState() => _SharePostCardState();
}

class _SharePostCardState extends State<SharePostCard> {
  late String _selectedReaction;

  @override
  void initState() {
    super.initState();
    _selectedReaction = widget.post.userReaction;
    // Refresh post data from backend to ensure we have the latest reaction state
    _refreshPostData();
  }

  void _handleReaction(String reaction) async {
    try {
      // Immediately update the UI for better user experience
      setState(() {
        // Allow changing reaction to a different emoji; prevent removal
        if (_selectedReaction == reaction) {
          // Same reaction tapped → do nothing
          return;
        }

        // If previously selected, decrement its count
        if (_selectedReaction.isNotEmpty) {
          switch (_selectedReaction) {
            case 'laugh':
              if (widget.post.laughCount > 0) widget.post.laughCount--;
              break;
            case 'heart':
              if (widget.post.heartCount > 0) widget.post.heartCount--;
              break;
            case 'hot':
              if (widget.post.hotCount > 0) widget.post.hotCount--;
              break;
            case 'broken_heart':
              if (widget.post.brokenHeartCount > 0) widget.post.brokenHeartCount--;
              break;
          }
        }

        // Set new selection and increment its count
        _selectedReaction = reaction;
        switch (reaction) {
          case 'laugh':
            widget.post.laughCount++;
            break;
          case 'heart':
            widget.post.heartCount++;
            break;
          case 'hot':
            widget.post.hotCount++;
            break;
          case 'broken_heart':
            widget.post.brokenHeartCount++;
            break;
        }
        
        // Update the post's user reaction
        widget.post.userReaction = _selectedReaction;
      });
      
      // Then sync with backend
      await ShareService.instance.updatePostReaction(widget.post.id, reaction, true);
      
    } catch (e) {
      print('Error handling reaction: $e');
      // If there's an error, revert the UI changes and show a message
      if (!mounted) return;
      setState(() {
        // Revert to previous state
        _selectedReaction = widget.post.userReaction;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reaction: $e')),
      );
    }
  }

  Future<void> _refreshPostData() async {
    try {
      // Get fresh post data from the backend
      final posts = await ShareService.instance.getAllSharedPosts();
      final updatedPost = posts.firstWhere((post) => post.id == widget.post.id);
      
      if (!mounted) return;
      setState(() {
        // Update the post data with fresh counts and user reaction
        widget.post.heartCount = updatedPost.heartCount;
        widget.post.laughCount = updatedPost.laughCount;
        widget.post.hotCount = updatedPost.hotCount;
        widget.post.brokenHeartCount = updatedPost.brokenHeartCount;
        widget.post.userReaction = updatedPost.userReaction;
        _selectedReaction = updatedPost.userReaction;
      });
    } catch (e) {
      print('Error refreshing post data: $e');
    }
  }

  Widget _buildReactionButton(String reaction, String imagePath, int count) {
    final isSelected = _selectedReaction == reaction;

    return GestureDetector(
      onTap: () => _handleReaction(reaction),
      child: Column(
        children: [
          ReactionButton(
            emojiPath: imagePath,
            isSelected: isSelected,
            onTap: () => _handleReaction(reaction),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: SwipzeeTypography.caption.copyWith(
              color: const Color(0xFF000000), // Black
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reaction buttons at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReactionButton('laugh', 'assets/icons-images/laughing Tears Emoji.png', widget.post.laughCount),
                _buildReactionButton('heart', 'assets/icons-images/Heart Eyes Emoji.png', widget.post.heartCount),
                _buildReactionButton('hot', 'assets/icons-images/Hot Emoji.png', widget.post.hotCount),
                _buildReactionButton('broken_heart', 'assets/icons-images/Broken Red Heart Emoji.png', widget.post.brokenHeartCount),
              ],
            ),
            const SizedBox(height: 16),
            // Post content with white background and black text
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white, // White background for the text
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    widget.post.text,
                    style: SwipzeeTypography.bodyLarge.copyWith(
                      color: Colors.black, // Black text
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
