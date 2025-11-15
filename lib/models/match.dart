class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final bool isMutual;
  final DateTime createdAt;
  final String? user1TypingStatus;
  final String? user2TypingStatus;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.isMutual = false,
    required this.createdAt,
    this.user1TypingStatus,
    this.user2TypingStatus,
  });

  Match copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    bool? isMutual,
    DateTime? createdAt,
    String? user1TypingStatus,
    String? user2TypingStatus,
  }) {
    return Match(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      isMutual: isMutual ?? this.isMutual,
      createdAt: createdAt ?? this.createdAt,
      user1TypingStatus: user1TypingStatus ?? this.user1TypingStatus,
      user2TypingStatus: user2TypingStatus ?? this.user2TypingStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'is_mutual': isMutual,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'user1_typing_status': user1TypingStatus,
      'user2_typing_status': user2TypingStatus,
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.now();
    }

    return Match(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      isMutual: json['is_mutual'] as bool? ?? false,
      createdAt: parseDateTime(json['created_at']),
      user1TypingStatus: json['user1_typing_status'] as String?,
      user2TypingStatus: json['user2_typing_status'] as String?,
    );
  }

  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  bool isTyping(String currentUserId) {
    if (user1Id == currentUserId) {
      return user2TypingStatus == 'typing';
    } else {
      return user1TypingStatus == 'typing';
    }
  }

  @override
  String toString() {
    return 'Match(id: $id, user1Id: $user1Id, user2Id: $user2Id, isMutual: $isMutual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
