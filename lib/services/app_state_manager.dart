import 'package:flutter/foundation.dart';

/// Global state manager for instant page rebuilds
class AppStateManager {
  static final AppStateManager _instance = AppStateManager._internal();
  factory AppStateManager() => _instance;
  AppStateManager._internal();

  static AppStateManager get instance => _instance;

  // State notifiers
  final ValueNotifier<int> postsUpdateNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> matchesUpdateNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> messagesUpdateNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> leaderboardUpdateNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> crushesUpdateNotifier = ValueNotifier<int>(0);

  // Notify methods
  void notifyPostsUpdated() {
    postsUpdateNotifier.value++;
  }

  void notifyMatchesUpdated() {
    matchesUpdateNotifier.value++;
  }

  void notifyMessagesUpdated() {
    messagesUpdateNotifier.value++;
  }

  void notifyProfileUpdated() {
    profileUpdateNotifier.value++;
  }

  void notifyLeaderboardUpdated() {
    leaderboardUpdateNotifier.value++;
  }

  void notifyCrushesUpdated() {
    crushesUpdateNotifier.value++;
  }

  // Notify all
  void notifyAll() {
    notifyPostsUpdated();
    notifyMatchesUpdated();
    notifyMessagesUpdated();
    notifyProfileUpdated();
    notifyLeaderboardUpdated();
    notifyCrushesUpdated();
  }

  void dispose() {
    postsUpdateNotifier.dispose();
    matchesUpdateNotifier.dispose();
    messagesUpdateNotifier.dispose();
    profileUpdateNotifier.dispose();
    leaderboardUpdateNotifier.dispose();
    crushesUpdateNotifier.dispose();
  }
}
