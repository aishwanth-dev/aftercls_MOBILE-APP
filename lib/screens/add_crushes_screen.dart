import 'package:flutter/material.dart';
import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/services/user_service.dart';
import 'package:campus_pulse/services/match_service.dart';
import 'package:campus_pulse/services/app_state_manager.dart';
import 'package:campus_pulse/auth/auth_manager.dart';
import 'package:campus_pulse/theme.dart';

class AddCrushesScreen extends StatefulWidget {
  const AddCrushesScreen({super.key});

  @override
  State<AddCrushesScreen> createState() => _AddCrushesScreenState();
}

class _AddCrushesScreenState extends State<AddCrushesScreen> {
  List<User> _availableUsers = [];
  List<User> _searchResults = [];
  Set<String> _currentCrushes = {};
  Set<String> _matchedUserIds = {}; // Track already matched users
  User? _currentUser;
  bool _isLoading = true;
  int _crushCount = 0;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      _currentUser = await DefaultAuthManager.instance.getCurrentUser();
      if (_currentUser == null) {
        print('Error: Current user is null in add crushes screen');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Current user in add crushes: ${_currentUser!.id}');

      final allUsers = await UserService.instance.getAllUsers();
      final crushes =
          await MatchService.instance.getUserCrushes(_currentUser!.id);
      final crushCount =
          await MatchService.instance.getUserCrushCount(_currentUser!.id);

      // Get all matches for current user
      final matches =
          await MatchService.instance.getUserMatches(_currentUser!.id);
      final matchedUserIds = <String>{};
      for (final match in matches) {
        // Add the other user's ID from each match
        if (match.user1Id == _currentUser!.id) {
          matchedUserIds.add(match.user2Id);
        } else {
          matchedUserIds.add(match.user1Id);
        }
      }

      // Filter out current user AND already matched users
      final availableUsers = allUsers
          .where((user) =>
              user.id != _currentUser!.id &&
              !matchedUserIds.contains(user.id)) // Hide matched users
          .toList();

      setState(() {
        _availableUsers = availableUsers;
        _searchResults = availableUsers;
        _currentCrushes = crushes.map((crush) => crush.toUserId).toSet();
        _matchedUserIds = matchedUserIds;
        _crushCount = crushCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load users: $e',
            style: SwipzeeTypography.buttonMedium.copyWith(
              color: SwipzeeColors.white,
            ),
          ),
          backgroundColor: SwipzeeColors.error,
        ),
      );
    }
  }

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _availableUsers;
      });
      return;
    }

    setState(() {
      _searchResults = _availableUsers
          .where((user) =>
              user.nickname.toLowerCase().contains(query.toLowerCase()) ||
              user.email.contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _toggleCrush(String userId) async {
    print(
        'Toggling crush for user: $userId, current user: ${_currentUser?.id}');

    if (_currentCrushes.contains(userId)) {
      // Remove crush
      final success = await MatchService.instance.removeCrush(
        fromUserId: _currentUser!.id,
        toUserId: userId,
      );

      if (success) {
        // Instant state update
        setState(() {
          _currentCrushes.remove(userId);
          _crushCount--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from your list')),
        );
      }
    } else {
      // Add crush - no limit
      final success = await MatchService.instance.addCrush(
        fromUserId: _currentUser!.id,
        toUserId: userId,
      );

      if (success) {
        // Instant state update
        setState(() {
          _currentCrushes.add(userId);
          _crushCount++;
        });

        // Notify state change
        AppStateManager.instance.notifyCrushesUpdated();
        AppStateManager.instance.notifyMatchesUpdated();

        // Show immediate feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to your list! 💕'),
            duration: Duration(seconds: 2),
          ),
        );

        // Check if it's a mutual match
        final isMatch =
            await MatchService.instance.isMatch(_currentUser!.id, userId);
        if (isMatch) {
          final user = _availableUsers.firstWhere(
            (u) => u.id == userId,
            orElse: () => User(
              id: userId,
              email: 'unknown@example.com',
              nickname: 'Unknown User',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          _showMatchDialog(user);
        }
      }
    }
  }

  void _showMatchDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'It\'s a Match!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You and ${user.nickname} liked each other!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Instant refresh - remove matched user from list
                setState(() {
                  _matchedUserIds.add(user.id);
                  _availableUsers.removeWhere((u) => u.id == user.id);
                  _searchResults.removeWhere((u) => u.id == user.id);
                  _currentCrushes.remove(user.id);
                });
                Navigator.of(context).pop(); // Go back to chat screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Start Chatting'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add People'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading classmates...',
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
      appBar: AppBar(
        title: const Text('Add People'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_crushCount',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                decoration: InputDecoration(
                  hintText: 'Search by name or student ID...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add people to your list. When they add you back, it\'s a match!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Users list
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final isSelected = _currentCrushes.contains(user.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _toggleCrush(user.id),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
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
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: user.avatarUrl != null
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: user.avatarUrl == null
                                        ? Text(
                                            (user.nickname.isNotEmpty
                                                ? user.nickname.characters.first
                                                    .toUpperCase()
                                                : 'U'),
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nickname,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_fire_department,
                                              size: 16,
                                              color: theme.colorScheme.tertiary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${user.totalFiresReceived} fires',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                              .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isSelected
                                          ? Colors.white
                                          : theme.colorScheme.outline,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
