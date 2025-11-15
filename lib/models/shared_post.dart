class SharedPost {
  final String id;
  final String text;
  final DateTime createdAt;
  int heartCount;
  int laughCount;
  int hotCount;
  int brokenHeartCount;
  String userReaction;

  SharedPost({
    required this.id,
    required this.text,
    required this.createdAt,
    this.heartCount = 0,
    this.laughCount = 0,
    this.hotCount = 0,
    this.brokenHeartCount = 0,
    this.userReaction = '',
  });

  factory SharedPost.fromJson(Map<String, dynamic> json) {
    return SharedPost(
      id: json['id'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      heartCount: json['heart_count'] ?? 0,
      laughCount: json['laugh_count'] ?? 0,
      hotCount: json['hot_count'] ?? 0,
      brokenHeartCount: json['broken_heart_count'] ?? 0,
      userReaction: json['user_reaction'] ?? '', // This will be empty initially, will be set later
    );
  }

  // Method to update reaction count
  void updateReactionCount(String reaction, int delta) {
    switch (reaction) {
      case 'laugh':
        laughCount += delta;
        break;
      case 'heart':
        heartCount += delta;
        break;
      case 'hot':
        hotCount += delta;
        break;
      case 'broken_heart':
        brokenHeartCount += delta;
        break;
    }
  }
}