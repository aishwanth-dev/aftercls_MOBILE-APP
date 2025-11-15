import 'dart:async';
import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/models/match.dart';
import 'package:campus_pulse/models/message.dart';
import 'package:campus_pulse/services/message_service.dart';
import 'package:campus_pulse/services/match_service.dart';
import 'package:campus_pulse/services/user_service.dart';
import 'package:campus_pulse/services/app_state_manager.dart';
import 'package:campus_pulse/screens/user_profile_view_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final Match match;
  final User otherUser;
  final User currentUser;

  const ChatDetailScreen({
    super.key,
    required this.match,
    required this.otherUser,
    required this.currentUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  List<Message> _messages = [];
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _messageTimer;
  Timer? _typingTimer;
  Timer? _onlineStatusTimer;
  bool _isOtherUserOnline = false;
  bool _isOtherUserTyping = false;
  Match? _currentMatch;
  final Map<String, AnimationController> _messageAnimations = {};
  bool _userHasScrolledUp = false; // Track if user has scrolled up manually

  @override
  void initState() {
    super.initState();
    _currentMatch = widget.match;

    // Mark messages as read when opening chat
    MessageService.instance
        .markMessagesAsRead(widget.match.id, widget.currentUser.id);

    // Load messages initially
    _loadMessages();

    // Poll for new messages every 1 second for faster updates
    _messageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadMessages();
      _checkOnlineStatus();
    });

    // Update our online status
    _updateOnlineStatus(true);

    // Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);

    // Listen to scroll position changes
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Check if user has scrolled up (not at the bottom)
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // If user is not at the bottom, set flag to true
      _userHasScrolledUp =
          currentScroll < (maxScroll - 50); // 50 pixels tolerance
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageTimer?.cancel();
    _typingTimer?.cancel();
    _onlineStatusTimer?.cancel();

    // Clear typing status and set offline
    _updateTypingStatus(false);
    _updateOnlineStatus(false);

    // Dispose all animation controllers
    for (var controller in _messageAnimations.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages =
          await MessageService.instance.getMessagesForMatch(widget.match.id);
      final match = await MatchService.instance.getMatchById(widget.match.id);

      if (mounted) {
        setState(() {
          final newMessageIds = messages.map((m) => m.id).toSet();
          final oldMessageIds = _messages.map((m) => m.id).toSet();

          // Find newly added messages
          final addedMessageIds = newMessageIds.difference(oldMessageIds);

          _messages = messages;
          _currentMatch = match ?? _currentMatch;
          _isLoading = false;

          // Check typing status
          if (_currentMatch != null) {
            _isOtherUserTyping = _currentMatch!.isTyping(widget.currentUser.id);
          }

          // Create animations for new messages
          for (final messageId in addedMessageIds) {
            if (!_messageAnimations.containsKey(messageId)) {
              final controller = AnimationController(
                duration: const Duration(milliseconds: 300),
                vsync: this,
              );
              _messageAnimations[messageId] = controller;
              controller.forward();
            }
          }
        });

        // Only scroll to bottom if user hasn't scrolled up manually
        if (!_userHasScrolledUp) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    // Clear typing status
    _updateTypingStatus(false);

    // Immediately clear the text field and update UI
    _messageController.clear();
    if (mounted) {
      setState(() {
        _isSending = true;
      });
    }

    // Reset scroll flag when sending a new message
    _userHasScrolledUp = false;

    try {
      final message = await MessageService.instance.sendMessage(
        matchId: widget.match.id,
        senderId: widget.currentUser.id,
        receiverId: widget.otherUser.id,
        content: content,
      );

      if (message != null) {
        // Create animation for new message
        final controller = AnimationController(
          duration: const Duration(milliseconds: 400),
          vsync: this,
        );
        _messageAnimations[message.id] = controller;

        if (mounted) {
          setState(() {
            _messages.add(message);
          });
        }

        controller.forward();
        _scrollToBottom();

        // Notify state change
        AppStateManager.instance.notifyMessagesUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTextChanged() {
    final isTyping = _messageController.text.trim().isNotEmpty;
    _updateTypingStatus(isTyping);
  }

  void _updateTypingStatus(bool isTyping) {
    _typingTimer?.cancel();

    MatchService.instance.updateTypingStatus(
      matchId: widget.match.id,
      userId: widget.currentUser.id,
      isTyping: isTyping,
    );

    if (isTyping) {
      // Auto-clear typing status after 3 seconds of no activity
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _updateTypingStatus(false);
      });
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    UserService.instance.updateOnlineStatus(
      userId: widget.currentUser.id,
      isOnline: isOnline,
    );
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final otherUser =
          await UserService.instance.getUserById(widget.otherUser.id);
      if (otherUser != null && mounted) {
        setState(() {
          _isOtherUserOnline = otherUser.isOnline;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (widget.otherUser.avatarUrl != null &&
                      widget.otherUser.avatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.otherUser.avatarUrl!)
                  : null,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: (widget.otherUser.avatarUrl == null ||
                      widget.otherUser.avatarUrl!.isEmpty)
                  ? Text(
                      (widget.otherUser.nickname.isNotEmpty
                          ? widget.otherUser.nickname.characters.first
                              .toUpperCase()
                          : 'U'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.nickname,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (_isOtherUserOnline)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        _isOtherUserTyping
                            ? 'typing...'
                            : (_isOtherUserOnline ? 'Online' : 'Offline'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              _isOtherUserOnline ? Colors.green : Colors.grey,
                          fontStyle: _isOtherUserTyping
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              _showOptionsBottomSheet(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Messages list
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : _messages.isEmpty
                            ? _buildEmptyState(theme)
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isMe =
                                      message.senderId == widget.currentUser.id;
                                  final showTime = index == 0 ||
                                      _messages[index - 1]
                                              .createdAt
                                              .difference(message.createdAt)
                                              .inMinutes
                                              .abs() >
                                          5;

                                  return _buildMessageBubble(
                                      message, isMe, showTime, theme);
                                },
                              ),
                  ),

                  // Message input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: _messageController,
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              onChanged: (_) => setState(
                                  () {}), // Force rebuild on text change
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSending ? null : _sendMessage,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _messageController.text.trim().isEmpty ||
                                      _isSending
                                  ? theme.colorScheme.outline
                                      .withValues(alpha: 0.3)
                                  : theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isSending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color:
                                        _messageController.text.trim().isEmpty
                                            ? theme.colorScheme.outline
                                            : Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Scroll to bottom button
              if (_userHasScrolledUp)
                Positioned(
                  right: 16,
                  bottom: 80,
                  child: GestureDetector(
                    onTap: _scrollToBottom,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You matched!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to ${widget.otherUser.nickname}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '💡 Start with a friendly greeting or ask about their posts!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Message message, bool isMe, bool showTime, ThemeData theme) {
    final animationController = _messageAnimations[message.id];

    Widget bubble = Column(
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _formatTime(message.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? theme.colorScheme.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft:
                    isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight:
                    isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );

    // Apply animation if available
    if (animationController != null) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0), // Bottom to top animation
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: animationController,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController,
                curve: Curves.easeOutBack,
              ),
            ),
            child: bubble,
          ),
        ),
      );
    }

    return bubble;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserProfileViewScreen(
                      user: widget.otherUser,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title:
                  const Text('Unfriend', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Unfriend'),
                    content: Text(
                      'Are you sure you want to unfriend ${widget.otherUser.nickname}? You will need to match again to chat.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Unfriend'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _unfriendUser();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report User',
                  style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report functionality coming soon'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unfriendUser() async {
    try {
      // Remove both crushes to unmatch
      await MatchService.instance.removeCrush(
        fromUserId: widget.currentUser.id,
        toUserId: widget.otherUser.id,
      );

      await MatchService.instance.removeCrush(
        fromUserId: widget.otherUser.id,
        toUserId: widget.currentUser.id,
      );

      // Delete the match
      await MatchService.instance.deleteMatch(widget.match.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have unfriended ${widget.otherUser.nickname}'),
        ),
      );

      // Go back to matches screen
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unfriend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
