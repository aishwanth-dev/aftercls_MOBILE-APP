import 'dart:math';
import 'package:campus_pulse/models/challenge.dart';
import 'package:campus_pulse/services/insforge_client.dart';

class ChallengeService {
  
  static ChallengeService? _instance;
  static ChallengeService get instance => _instance ??= ChallengeService._();
  ChallengeService._();

  final InsforgeClient _client = InsforgeClient.instance;

  List<Challenge> _generateSampleChallenges() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return [
      // Current week challenge
      Challenge(
        id: 'challenge_current',
        title: 'Smile Challenge',
        hashtag: '#Smile',
        startDate: startOfWeek,
        endDate: startOfWeek.add(const Duration(days: 7)),
        isActive: true,
      ),
      
      // Next week challenge
      Challenge(
        id: 'challenge_next',
        title: 'Aesthetic Vibes',
        hashtag: '#Aesthetic',
        startDate: startOfWeek.add(const Duration(days: 7)),
        endDate: startOfWeek.add(const Duration(days: 14)),
        isActive: true,
      ),
      
      // Previous week challenge (for demo)
      Challenge(
        id: 'challenge_previous',
        title: 'Campus Life',
        hashtag: '#CampusLife',
        startDate: startOfWeek.subtract(const Duration(days: 7)),
        endDate: startOfWeek,
        isActive: false,
      ),
      
      // Future challenges
      Challenge(
        id: 'challenge_future1',
        title: 'Study Vibes',
        hashtag: '#StudyVibes',
        startDate: startOfWeek.add(const Duration(days: 14)),
        endDate: startOfWeek.add(const Duration(days: 21)),
        isActive: true,
      ),
      
      Challenge(
        id: 'challenge_future2',
        title: 'Hot Pic Contest',
        hashtag: '#HotPic',
        startDate: startOfWeek.add(const Duration(days: 21)),
        endDate: startOfWeek.add(const Duration(days: 28)),
        isActive: true,
      ),
    ];
  }

  Future<List<Challenge>> getAllChallenges() async {
    try {
      // Try to get from Insforge database first
      final challengesData = await _client.select(
        table: 'challenges',
        orderBy: 'start_date.desc',
      );
      
      if (challengesData.isNotEmpty) {
        return challengesData.map((data) => Challenge.fromJson(data)).toList();
      }
      
      // If no challenges in database, return sample challenges
      return _generateSampleChallenges();
    } catch (e) {
      print('Error getting challenges from database: $e');
      // Fallback to sample challenges
      return _generateSampleChallenges();
    }
  }

  Future<Challenge?> getCurrentChallenge() async {
    try {
      final challenges = await getAllChallenges();
      final now = DateTime.now();
      
      // First try to find an active challenge within date range
      final activeInRange = challenges.where(
        (challenge) => challenge.isActive && 
                      challenge.startDate.isBefore(now) && 
                      challenge.endDate.isAfter(now),
      ).toList();
      
      if (activeInRange.isNotEmpty) {
        return activeInRange.first;
      }
      
      // If no active challenge in range, find any active challenge
      final activeChallenges = challenges.where(
        (challenge) => challenge.isActive,
      ).toList();
      
      if (activeChallenges.isNotEmpty) {
        return activeChallenges.first;
      }
      
      // If no active challenges, return the first challenge if any exist
      return challenges.isNotEmpty ? challenges.first : null;
    } catch (e) {
      print('Error getting current challenge: $e');
      return null;
    }
  }

  Future<Challenge?> getUpcomingChallenge() async {
    try {
      final challenges = await getAllChallenges();
      final now = DateTime.now();
      
      final upcomingChallenges = challenges
          .where((challenge) => 
              challenge.isActive && 
              challenge.startDate.isAfter(now)
          )
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      
      return upcomingChallenges.isNotEmpty ? upcomingChallenges.first : null;
    } catch (e) {
      print('Error getting upcoming challenge: $e');
      return null;
    }
  }

  Future<List<Challenge>> getActiveChallenges() async {
    try {
      final challenges = await getAllChallenges();
      return challenges.where((challenge) => challenge.isActive).toList();
    } catch (e) {
      print('Error getting active challenges: $e');
      return [];
    }
  }

  Future<List<Challenge>> getPastChallenges() async {
    try {
      final challenges = await getAllChallenges();
      final now = DateTime.now();
      
      return challenges
          .where((challenge) => challenge.endDate.isBefore(now))
          .toList()
        ..sort((a, b) => b.endDate.compareTo(a.endDate)); // Most recent first
    } catch (e) {
      print('Error getting past challenges: $e');
      return [];
    }
  }

  Future<Challenge?> createChallenge({
    required String title,
    required String hashtag,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = true,
  }) async {
    try {
      // Ensure hashtag starts with #
      String formattedHashtag = hashtag;
      if (!formattedHashtag.startsWith('#')) {
        formattedHashtag = '#$hashtag';
      }

      final challengeData = {
        'title': title,
        'hashtag': formattedHashtag,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': isActive,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _client.insert(
        table: 'challenges',
        data: challengeData,
      );
      
      return Challenge.fromJson(result);
    } catch (e) {
      print('Error creating challenge: $e');
      return null;
    }
  }

  Future<Challenge?> getChallengeById(String challengeId) async {
    try {
      final challengesData = await _client.select(
        table: 'challenges',
        filters: {'id': challengeId},
      );
      
      if (challengesData.isNotEmpty) {
        return Challenge.fromJson(challengesData.first);
      }
      return null;
    } catch (e) {
      print('Error getting challenge by ID: $e');
      return null;
    }
  }

  Future<Challenge?> getChallengeByHashtag(String hashtag) async {
    try {
      final challenges = await getAllChallenges();
      final matchingChallenges = challenges.where(
        (challenge) => challenge.hashtag.toLowerCase() == hashtag.toLowerCase(),
      ).toList();
      
      return matchingChallenges.isNotEmpty ? matchingChallenges.first : null;
    } catch (e) {
      print('Error getting challenge by hashtag: $e');
      return null;
    }
  }

  Future<Challenge?> updateChallenge(Challenge updatedChallenge) async {
    try {
      final challengeData = updatedChallenge.toJson();
      challengeData['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client.update(
        table: 'challenges',
        data: challengeData,
        filters: {'id': updatedChallenge.id},
      );
      
      return Challenge.fromJson(result);
    } catch (e) {
      print('Error updating challenge: $e');
      return null;
    }
  }

  Future<bool> deactivateChallenge(String challengeId) async {
    try {
      final challenge = await getChallengeById(challengeId);
      if (challenge != null) {
        final updatedChallenge = challenge.copyWith(isActive: false);
        final result = await updateChallenge(updatedChallenge);
        return result != null;
      }
      return false;
    } catch (e) {
      print('Error deactivating challenge: $e');
      return false;
    }
  }

  Future<bool> deleteChallenge(String challengeId) async {
    try {
      await _client.delete(
        table: 'challenges',
        filters: {'id': challengeId},
      );
      return true;
    } catch (e) {
      print('Error deleting challenge: $e');
      return false;
    }
  }

  Future<String?> getCurrentChallengeHashtag() async {
    try {
      final currentChallenge = await getCurrentChallenge();
      return currentChallenge?.hashtag;
    } catch (e) {
      print('Error getting current challenge hashtag: $e');
      return null;
    }
  }

  Future<List<String>> getAllActiveHashtags() async {
    try {
      final challenges = await getActiveChallenges();
      return challenges.map((challenge) => challenge.hashtag).toList();
    } catch (e) {
      print('Error getting all active hashtags: $e');
      return [];
    }
  }

  Future<Duration?> getTimeUntilCurrentChallengeEnds() async {
    try {
      final currentChallenge = await getCurrentChallenge();
      if (currentChallenge != null) {
        return currentChallenge.endDate.difference(DateTime.now());
      }
      return null;
    } catch (e) {
      print('Error getting time until current challenge ends: $e');
      return null;
    }
  }

  Future<Duration?> getTimeUntilNextChallengeStarts() async {
    try {
      final upcomingChallenge = await getUpcomingChallenge();
      if (upcomingChallenge != null) {
        return upcomingChallenge.startDate.difference(DateTime.now());
      }
      return null;
    } catch (e) {
      print('Error getting time until next challenge starts: $e');
      return null;
    }
  }

  // Generate next week's challenge automatically
  Future<Challenge?> generateNextWeekChallenge() async {
    try {
      final challengeTitles = [
        'Smile Challenge',
        'Aesthetic Vibes',
        'Campus Life',
        'Study Vibes',
        'Hot Pic Contest',
        'Friend Goals',
        'Nature Shots',
        'Creative Mode',
        'Weekend Vibes',
        'Sporty Look'
      ];

      final hashtags = [
        '#Smile',
        '#Aesthetic',
        '#CampusLife',
        '#StudyVibes',
        '#HotPic',
        '#FriendGoals',
        '#Nature',
        '#Creative',
        '#Weekend',
        '#Sporty'
      ];

      final random = Random();
      final index = random.nextInt(challengeTitles.length);
      
      final now = DateTime.now();
      final nextWeekStart = now.add(Duration(days: 7 - now.weekday + 1));
      final nextWeekEnd = nextWeekStart.add(const Duration(days: 7));

      return await createChallenge(
        title: challengeTitles[index],
        hashtag: hashtags[index],
        startDate: nextWeekStart,
        endDate: nextWeekEnd,
      );
    } catch (e) {
      print('Error generating next week challenge: $e');
      return null;
    }
  }

  // Initialize sample challenges in database
  Future<void> initializeSampleChallenges() async {
    try {
      final existingChallenges = await _client.select(table: 'challenges');
      
      if (existingChallenges.isEmpty) {
        final sampleChallenges = _generateSampleChallenges();
        
        for (final challenge in sampleChallenges) {
          await _client.insert(
            table: 'challenges',
            data: challenge.toJson(),
          );
        }
        
        print('Sample challenges initialized successfully');
      }
    } catch (e) {
      print('Error initializing sample challenges: $e');
    }
  }
}