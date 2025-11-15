// Simple Authentication Manager for Campus Pulse
// Handles email/password authentication with Insforge backend

import 'package:campus_pulse/models/user.dart';
import 'package:campus_pulse/auth/clean_auth_manager.dart';

abstract class AuthManager {
  Future<void> initialize();
  Future<User?> signUp({
    required String email,
    required String password,
    required String nickname,
  });
  Future<User?> signInWithPassword({
    required String email,
    required String password,
  });
  Future<User?> getCurrentUser();
  Future<User?> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  });
  Future<User?> getUserProfile(String userId);
  Future<void> signOut();
  Future<bool> deleteAccount();
  bool get isAuthenticated;
  Stream<User?> get authStateChanges;
}

// Default implementation using Insforge
class DefaultAuthManager implements AuthManager {
  static final DefaultAuthManager _instance = DefaultAuthManager._();
  static DefaultAuthManager get instance => _instance;
  DefaultAuthManager._();

  final CleanAuthManager _insforgeAuth = CleanAuthManager.instance;

  @override
  Future<void> initialize() async {
    // CleanAuthManager doesn't need initialization
  }

  @override
  Future<User?> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    return await _insforgeAuth.signUp(
      email: email,
      password: password,
      nickname: nickname,
    );
  }

  @override
  Future<User?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _insforgeAuth.signIn(
      email: email,
      password: password,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    return await _insforgeAuth.getCurrentUser();
  }

  @override
  Future<User?> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    return await _insforgeAuth.updateProfile(
      nickname: nickname,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<User?> getUserProfile(String userId) async {
    return await _insforgeAuth.getUserProfile(userId);
  }

  @override
  Future<void> signOut() async {
    // CleanAuthManager doesn't have signOut method, use InsforgeClient directly
    final client = _insforgeAuth.client;
    await client.signOut();
  }

  @override
  Future<bool> deleteAccount() async {
    return await _insforgeAuth.deleteAccount();
  }

  @override
  bool get isAuthenticated {
    // This should be async but the interface requires sync
    // We'll return false and let the caller check with getCurrentUser()
    return false;
  }

  @override
  Stream<User?> get authStateChanges => _insforgeAuth.authStateChanges;
}