import 'user.dart';

class LeaderboardPost {
  final String id;
  final String imageUrl;
  final String? caption;
  final int firesCount;
  final int rank;
  final String userId;
  final User user;

  const LeaderboardPost({
    required this.id,
    required this.imageUrl,
    this.caption,
    required this.firesCount,
    required this.rank,
    required this.userId,
    required this.user,
  });

  LeaderboardPost copyWith({
    String? id,
    String? imageUrl,
    String? caption,
    int? firesCount,
    int? rank,
    String? userId,
    User? user,
  }) {
    return LeaderboardPost(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      firesCount: firesCount ?? this.firesCount,
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'caption': caption,
      'fires_count': firesCount,
      'rank': rank,
      'user_id': userId,
    };
  }

  factory LeaderboardPost.fromJson(Map<String, dynamic> json, [User? user]) {
    return LeaderboardPost(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      firesCount: json['fires_count'] as int,
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      user: user ?? User(
        id: json['user_id'] as String,
        email: '',
        nickname: 'Unknown',
        bio: '',
        avatarUrl: null,
        birthday: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  String toString() {
    return 'LeaderboardPost(id: $id, firesCount: $firesCount, rank: $rank)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardPost &&
        other.id == id &&
        other.imageUrl == imageUrl &&
        other.caption == caption &&
        other.firesCount == firesCount &&
        other.rank == rank &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        imageUrl.hashCode ^
        caption.hashCode ^
        firesCount.hashCode ^
        rank.hashCode ^
        userId.hashCode;
  }
}
