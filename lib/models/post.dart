import 'user.dart';

class Post {
  final String id;
  final String userId;
  final String imageUrl;
  final String? imageKey; // Storage key for programmatic access
  final String? caption; // Optional - only for special posts
  final String? challengeTag;
  final int firesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user; // User object for display

  Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.imageKey,
    this.caption,
    this.challengeTag,
    this.firesCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  Post copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? imageKey,
    String? caption,
    String? challengeTag,
    int? firesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? user,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      imageKey: imageKey ?? this.imageKey,
      caption: caption ?? this.caption,
      challengeTag: challengeTag ?? this.challengeTag,
      firesCount: firesCount ?? this.firesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'image_key': imageKey,
      'caption': caption,
      'challenge_tag': challengeTag,
      'fires_count': firesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Post.fromJson(Map<String, dynamic> json, [User? user]) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return Post(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      imageUrl: (json['image_url'] ?? '') as String,
      imageKey: json['image_key'] as String?,
      caption: json['caption'] as String?,
      challengeTag: json['challenge_tag'] as String?,
      firesCount: json['fires_count'] as int? ?? 0,
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      user: user,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, userId: $userId, firesCount: $firesCount, challengeTag: $challengeTag)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}