class UserRankInfo {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final int rank;
  final int points;
  final String period; // 'daily', 'weekly', 'all-time'

  const UserRankInfo({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.rank,
    required this.points,
    required this.period,
  });

  UserRankInfo copyWith({
    String? userId,
    String? nickname,
    String? avatarUrl,
    int? rank,
    int? points,
    String? period,
  }) {
    return UserRankInfo(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      points: points ?? this.points,
      period: period ?? this.period,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'rank': rank,
      'points': points,
      'period': period,
    };
  }

  factory UserRankInfo.fromJson(Map<String, dynamic> json) {
    return UserRankInfo(
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      rank: json['rank'] as int,
      points: json['points'] as int,
      period: json['period'] as String,
    );
  }

  @override
  String toString() {
    return 'UserRankInfo(userId: $userId, nickname: $nickname, rank: $rank, points: $points, period: $period)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRankInfo &&
        other.userId == userId &&
        other.nickname == nickname &&
        other.avatarUrl == avatarUrl &&
        other.rank == rank &&
        other.points == points &&
        other.period == period;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        nickname.hashCode ^
        avatarUrl.hashCode ^
        rank.hashCode ^
        points.hashCode ^
        period.hashCode;
  }
}
