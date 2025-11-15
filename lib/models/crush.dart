class Crush {
  final String id;
  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;
  final DateTime expiresAt;

  Crush({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
    required this.expiresAt,
  });

  Crush copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Crush(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  factory Crush.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.now();
    }

    return Crush(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      createdAt: parseDateTime(json['created_at']),
      expiresAt: parseDateTime(json['expires_at']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  String toString() {
    return 'Crush(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, isExpired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Crush && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}