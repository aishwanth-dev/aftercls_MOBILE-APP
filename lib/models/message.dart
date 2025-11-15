class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  Message copyWith({
    String? id,
    String? matchId,
    String? senderId,
    String? content,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.now();
    }

    return Message(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: parseDateTime(json['created_at']),
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}