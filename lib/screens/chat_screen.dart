import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/models/match.dart';
import 'package:campus_pulse/models/message.dart';
import 'package:campus_pulse/services/user_service.dart';
import 'package:campus_pulse/services/match_service.dart';
import 'package:campus_pulse/services/message_service.dart';
import 'package:campus_pulse/widgets/match_tile.dart';
import 'package:campus_pulse/screens/add_crushes_screen.dart';
import 'package:campus_pulse/screens/chat_detail_screen.dart';
import 'package:campus_pulse/auth/auth_manager.dart';
import 'package:campus_pulse/theme.dart';
import 'package:campus_pulse/services/app_state_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Match> _matches = [];
  List<User> _users = [];
  Map<String, Message?> _lastMessages = {};
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();

    // Listen to state changes
    AppStateManager.instance.matchesUpdateNotifier.addListener(_loadMatches);
    AppStateManager.instance.messagesUpdateNotifier.addListener(_loadMatches);
  }

  @override
  void dispose() {
    AppStateManager.instance.matchesUpdateNotifier.removeListener(_loadMatches);
    AppStateManager.instance.messagesUpdateNotifier
        .removeListener(_loadMatches);
    super.dispose();
  }

  Future<void> _loadMatches() async {
    try {
      _currentUser = await DefaultAuthManager.instance.getCurrentUser();
      if (_currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final matches =
          await MatchService.instance.getUserMatches(_currentUser!.id);
      final users = await UserService.instance.getAllUsers();

      // Load last message for each match
      final lastMessages = <String, Message?>{};
      for (final match in matches) {
        final messages =
            await MessageService.instance.getMessagesForMatch(match.id);
        if (messages.isNotEmpty) {
          lastMessages[match.id] = messages.last;
        }
      }

      print('Loaded ${matches.length} matches and ${users.length} users');
      for (final user in users) {
        print('User: ${user.nickname} (${user.id})');
      }

      setState(() {
        _matches = matches;
        _users = users;
        _lastMessages = lastMessages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load matches: $e',
            style: SwipzeeTypography.buttonMedium.copyWith(
              color: SwipzeeColors.white,
            ),
          ),
          backgroundColor: SwipzeeColors.error,
        ),
      );
    }
  }

  User? _getUserById(String userId) {
    try {
      return _users.firstWhere(
        (user) => user.id == userId,
        orElse: () => User(
          id: userId,
          email: 'unknown@example.com',
          nickname: 'Unknown User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  void _navigateToAddCrushes() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const AddCrushesScreen(),
      ),
    )
        .then((_) {
      // Instant rebuild
      AppStateManager.instance.notifyMatchesUpdated();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh matches when screen becomes active
    _loadMatches();
  }

  void _navigateToChatDetail(Match match) {
    final otherUserId = match.getOtherUserId(_currentUser!.id);
    final otherUser = _getUserById(otherUserId);

    if (otherUser != null) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            match: match,
            otherUser: otherUser,
            currentUser: _currentUser!,
          ),
        ),
      )
          .then((_) {
        // Instant rebuild after chat
        AppStateManager.instance.notifyMessagesUpdated();
      });
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
                'Loading your matches...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
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
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Messages',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          _matches.length == 1
                              ? '1 match'
                              : '${_matches.length} matches',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _navigateToAddCrushes,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_add,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Add',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Matches list
              Expanded(
                child: _matches.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: _loadMatches,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _matches.length,
                          itemBuilder: (context, index) {
                            final match = _matches[index];
                            final otherUserId =
                                match.getOtherUserId(_currentUser!.id);
                            final otherUser = _getUserById(otherUserId);

                            if (otherUser == null) return const SizedBox();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MatchTile(
                                user: otherUser,
                                match: match,
                                lastMessage: _lastMessages[match.id],
                                currentUserId: _currentUser!.id,
                                onTap: () => _navigateToChatDetail(match),
                              ),
                            );
                          },
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No matches yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding people you\'re interested in\nto find mutual matches!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddCrushes,
            icon: const Icon(Icons.person_add),
            label: const Text('Add People'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Add up to 10 people to your crush list\n'
                  '• When someone adds you back, it\'s a match!\n'
                  '• Only mutual matches can chat together',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
