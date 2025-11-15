import 'user.dart';

class LeaderboardUser {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final int points;
  final int rank;
  final User user;

  const LeaderboardUser({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.points,
    required this.rank,
    required this.user,
  });

  LeaderboardUser copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    int? points,
    int? rank,
    User? user,
  }) {
    return LeaderboardUser(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'points': points,
      'rank': rank,
    };
  }

  factory LeaderboardUser.fromJson(Map<String, dynamic> json, [User? user]) {
    return LeaderboardUser(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int,
      rank: json['rank'] as int,
      user: user ?? User(
        id: json['id'] as String,
        email: '',
        nickname: json['nickname'] as String,
        bio: '',
        avatarUrl: json['avatar_url'] as String?,
        birthday: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  String toString() {
    return 'LeaderboardUser(id: $id, nickname: $nickname, points: $points, rank: $rank)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardUser &&
        other.id == id &&
        other.nickname == nickname &&
        other.avatarUrl == avatarUrl &&
        other.points == points &&
        other.rank == rank;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nickname.hashCode ^
        avatarUrl.hashCode ^
        points.hashCode ^
        rank.hashCode;
  }
}
