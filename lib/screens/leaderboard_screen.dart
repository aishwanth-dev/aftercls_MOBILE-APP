import 'package:flutter/material.dart';
import 'package:campus_pulse/services/leaderboard_service.dart';
import 'package:campus_pulse/services/app_state_manager.dart';
import 'package:campus_pulse/widgets/leaderboard_tile.dart';
import 'package:campus_pulse/models/leaderboard_user.dart';
import 'package:campus_pulse/models/leaderboard_post.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardUser> _dailyTop = [];
  List<LeaderboardUser> _weeklyTop = [];
  List<LeaderboardUser> _monthlyTop = [];
  List<LeaderboardUser> _overallTop = [];
  List<LeaderboardPost> _challengeTop = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLeaderboards();

    // Listen to state changes
    AppStateManager.instance.leaderboardUpdateNotifier
        .addListener(_loadLeaderboards);
    AppStateManager.instance.postsUpdateNotifier.addListener(_loadLeaderboards);
  }

  @override
  void dispose() {
    _tabController.dispose();
    AppStateManager.instance.leaderboardUpdateNotifier
        .removeListener(_loadLeaderboards);
    AppStateManager.instance.postsUpdateNotifier
        .removeListener(_loadLeaderboards);
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    try {
      final dailyTop = await LeaderboardService.instance.getDailyTopUsers();
      final weeklyTop = await LeaderboardService.instance.getWeeklyTopUsers();
      final monthlyTop = await LeaderboardService.instance.getMonthlyTopUsers();
      final overallTop =
          await LeaderboardService.instance.getAllTimeTopUsers(); // No limit
      final challengeTop =
          await LeaderboardService.instance.getChallengeTopPosts();

      if (!mounted) return;
      setState(() {
        _dailyTop = dailyTop;
        _weeklyTop = weeklyTop;
        _monthlyTop = monthlyTop;
        _overallTop = overallTop;
        _challengeTop = challengeTop;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load leaderboards: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Daily Top 100'),
                Tab(text: 'Weekly Top 100'),
                Tab(text: 'Monthly Top 100'),
                Tab(text: 'Overall Rankings'),
              ],
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: theme.colorScheme.primary,
            ),
          ),
        ),
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
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading leaderboards...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyLeaderboard(),
                  _buildWeeklyLeaderboard(),
                  _buildMonthlyLeaderboard(),
                  _buildOverallLeaderboard(),
                ],
              ),
      ),
    );
  }

  Widget _buildDailyLeaderboard() {
    if (_dailyTop.isEmpty) {
      return _buildEmptyState('No daily rankings available');
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: Column(
        children: [
          // Top 3 podium
          if (_dailyTop.length >= 3) _buildPodium(_dailyTop.take(3).toList()),

          // Rest of the list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _dailyTop.length > 3
                  ? _dailyTop.length - 3
                  : _dailyTop.length,
              itemBuilder: (context, index) {
                final actualIndex = _dailyTop.length > 3 ? index + 3 : index;
                final leaderboardUser = _dailyTop[actualIndex];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LeaderboardTile(
                    user: leaderboardUser.user,
                    rank: leaderboardUser.rank,
                    score: leaderboardUser.points,
                    scoreLabel: 'fires today',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyLeaderboard() {
    if (_weeklyTop.isEmpty) {
      return _buildEmptyState('No weekly rankings available');
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: Column(
        children: [
          // Top 3 podium
          if (_weeklyTop.length >= 3) _buildPodium(_weeklyTop.take(3).toList()),

          // Rest of the list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _weeklyTop.length > 3
                  ? _weeklyTop.length - 3
                  : _weeklyTop.length,
              itemBuilder: (context, index) {
                final actualIndex = _weeklyTop.length > 3 ? index + 3 : index;
                final leaderboardUser = _weeklyTop[actualIndex];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LeaderboardTile(
                    user: leaderboardUser.user,
                    rank: leaderboardUser.rank,
                    score: leaderboardUser.points,
                    scoreLabel: 'fires this week',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeLeaderboard() {
    if (_challengeTop.isEmpty) {
      return _buildEmptyState('No challenge rankings available');
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _challengeTop.length,
        itemBuilder: (context, index) {
          final challengePost = _challengeTop[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildChallengePostCard(challengePost),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyLeaderboard() {
    if (_monthlyTop.isEmpty) {
      return _buildEmptyState('No monthly rankings available');
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: Column(
        children: [
          // Top 3 podium
          if (_monthlyTop.length >= 3)
            _buildPodium(_monthlyTop.take(3).toList()),

          // Rest of the list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _monthlyTop.length > 3
                  ? _monthlyTop.length - 3
                  : _monthlyTop.length,
              itemBuilder: (context, index) {
                final actualIndex = _monthlyTop.length > 3 ? index + 3 : index;
                final leaderboardUser = _monthlyTop[actualIndex];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LeaderboardTile(
                    user: leaderboardUser.user,
                    rank: leaderboardUser.rank,
                    score: leaderboardUser.points,
                    scoreLabel: 'fires this month',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallLeaderboard() {
    if (_overallTop.isEmpty) {
      return _buildEmptyState('No overall rankings available');
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: Column(
        children: [
          // Top 3 podium
          if (_overallTop.length >= 3)
            _buildPodium(_overallTop.take(3).toList()),

          // Rest of the list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _overallTop.length > 3
                  ? _overallTop.length - 3
                  : _overallTop.length,
              itemBuilder: (context, index) {
                final actualIndex = _overallTop.length > 3 ? index + 3 : index;
                final leaderboardUser = _overallTop[actualIndex];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LeaderboardTile(
                    user: leaderboardUser.user,
                    rank: leaderboardUser.rank,
                    score: leaderboardUser.points,
                    scoreLabel: 'fires overall',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardUser> topThree) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Rearrange to show 2nd, 1st, 3rd (traditional podium layout)
    final podiumOrder = [
      if (topThree.length > 1) topThree[1], // 2nd place
      topThree[0], // 1st place
      if (topThree.length > 2) topThree[2], // 3rd place
    ];

    // Responsive sizing
    final avatarRadius = isMobile ? 20.0 : 25.0;
    final podiumWidth = isMobile ? 50.0 : 60.0;
    final heights = isMobile
        ? [110.0, 130.0, 90.0] // 2nd, 1st, 3rd
        : [140.0, 160.0, 120.0];

    return Container(
      height: isMobile ? 170 : 200,
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: podiumOrder.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;

          final colors = [
            Colors.grey[400]!, // 2nd
            Colors.amber, // 1st
            Colors.brown[400]!, // 3rd
          ];
          final ranks = [2, 1, 3];

          return Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // User avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundImage: user.user.avatarUrl != null
                          ? NetworkImage(user.user.avatarUrl!)
                          : null,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: user.user.avatarUrl == null
                          ? Text(
                              (user.user.nickname.isNotEmpty
                                  ? user.user.nickname.characters.first
                                      .toUpperCase()
                                  : 'U'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 18,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: isMobile ? 20 : 24,
                        height: isMobile ? 20 : 24,
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${ranks[index]}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 4 : 8),

                // User name
                Text(
                  user.user.nickname,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 10 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Score
                Text(
                  '${user.points}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors[index],
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 9 : 11,
                  ),
                ),

                const SizedBox(height: 4),

                // Podium block
                Container(
                  width: podiumWidth,
                  height: heights[index],
                  decoration: BoxDecoration(
                    color: colors[index].withValues(alpha: 0.2),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(
                      top: BorderSide(color: colors[index], width: 3),
                      left: BorderSide(color: colors[index], width: 2),
                      right: BorderSide(color: colors[index], width: 2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ranks[index] == 1
                            ? Icons.emoji_events
                            : ranks[index] == 2
                                ? Icons.military_tech
                                : Icons.workspace_premium,
                        color: colors[index],
                        size: isMobile ? 24 : 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ranks[index]}${_getOrdinalSuffix(ranks[index])}',
                        style: TextStyle(
                          color: colors[index],
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChallengePostCard(LeaderboardPost challengePost) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(challengePost.rank).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${challengePost.rank}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getRankColor(challengePost.rank),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Post image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: challengePost.imageUrl.isNotEmpty
                ? Image.network(
                    challengePost.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: theme.colorScheme.surface,
                        child: Icon(
                          Icons.image,
                          color: theme.colorScheme.outline,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: theme.colorScheme.surface,
                    child: Icon(
                      Icons.image,
                      color: theme.colorScheme.outline,
                    ),
                  ),
          ),

          const SizedBox(width: 16),

          // User and post info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challengePost.user.nickname,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (challengePost.caption?.isNotEmpty ?? false)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      challengePost.caption!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challengePost.firesCount} fires',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadLeaderboards,
            child: const Text('Refresh'),
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
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
