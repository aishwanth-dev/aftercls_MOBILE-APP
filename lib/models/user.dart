class User {
  final String id;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final DateTime? birthday;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final bool isOnline;

  // Additional fields for Campus Pulse functionality
  final int dailyStreak;
  final int postsCount;
  final int totalFiresReceived;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.birthday,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    this.isOnline = false,
    this.dailyStreak = 0,
    this.postsCount = 0,
    this.totalFiresReceived = 0,
  });

  User copyWith({
    String? id,
    String? email,
    String? nickname,
    String? avatarUrl,
    String? bio,
    DateTime? birthday,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    bool? isOnline,
    int? dailyStreak,
    int? postsCount,
    int? totalFiresReceived,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      birthday: birthday ?? this.birthday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      postsCount: postsCount ?? this.postsCount,
      totalFiresReceived: totalFiresReceived ?? this.totalFiresReceived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'bio': bio,
      'birthday': birthday?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_online': isOnline,
      'daily_streak': dailyStreak,
      'posts_count': postsCount,
      'total_fires_received': totalFiresReceived,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    bool isUserOnline(dynamic lastSeenValue) {
      if (lastSeenValue == null) return false;
      final lastSeen = parseDateTime(lastSeenValue);
      final difference = DateTime.now().difference(lastSeen);
      return difference.inMinutes < 5; // Online if seen within 5 minutes
    }

    return User(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      nickname: (json['nickname'] ?? '') as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      birthday:
          json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      lastSeenAt: json['last_seen_at'] != null
          ? parseDateTime(json['last_seen_at'])
          : null,
      isOnline:
          json['is_online'] as bool? ?? isUserOnline(json['last_seen_at']),
      dailyStreak: json['daily_streak'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      totalFiresReceived: json['total_fires_received'] as int? ?? 0,
    );
  }

  // Factory method for creating from Insforge auth response
  factory User.fromInsforgeAuth(Map<String, dynamic> authData) {
    // Handle different response formats
    Map<String, dynamic> user;
    Map<String, dynamic> profile;

    if (authData.containsKey('user')) {
      // Standard format: { user: {...}, profile: {...} }
      user = authData['user'] as Map<String, dynamic>;
      profile = authData['profile'] as Map<String, dynamic>? ?? {};
    } else if (authData.containsKey('id') && authData.containsKey('email')) {
      // Direct format: { id: ..., email: ..., nickname: ... }
      user = authData;
      profile = authData;
    } else {
      // Fallback: treat entire response as user data
      user = authData;
      profile = authData;
    }

    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
      return DateTime.now();
    }

    // Extract user information
    final userId = user['id'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final name = user['name'] as String?;

    // Use nickname from profile if available, otherwise use name or email prefix
    final nickname = profile['nickname'] as String? ??
        name ??
        (email.isNotEmpty ? email.split('@')[0] : 'User');

    return User(
      id: userId,
      email: email,
      nickname: nickname,
      avatarUrl: profile['avatar_url'] as String?,
      bio: profile['bio'] as String? ?? '',
      birthday: profile['birthday'] != null
          ? DateTime.parse(profile['birthday'])
          : null,
      createdAt: parseDateTime(profile['created_at'] ?? user['createdAt']),
      updatedAt: parseDateTime(profile['updated_at'] ?? user['updatedAt']),
      lastSeenAt: profile['last_seen_at'] != null
          ? parseDateTime(profile['last_seen_at'])
          : null,
      isOnline: profile['is_online'] as bool? ?? false,
      dailyStreak: profile['daily_streak'] as int? ?? 0,
      postsCount: profile['posts_count'] as int? ?? 0,
      totalFiresReceived: profile['total_fires_received'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, nickname: $nickname, dailyStreak: $dailyStreak, postsCount: $postsCount, totalFiresReceived: $totalFiresReceived)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
