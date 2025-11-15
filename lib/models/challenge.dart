class Challenge {
  final String id;
  final String title;
  final String hashtag;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Challenge({
    required this.id,
    required this.title,
    required this.hashtag,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? hashtag,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      hashtag: hashtag ?? this.hashtag,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hashtag': hashtag,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) return DateTime.parse(value);
      if (value.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        return (value as dynamic).toDate() as DateTime;
      }
      return DateTime.now();
    }

    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      hashtag: json['hashtag'] as String,
      startDate: parseDateTime(json['start_date']),
      endDate: parseDateTime(json['end_date']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  String toString() {
    return 'Challenge(id: $id, title: $title, hashtag: $hashtag, isActive: $isCurrentlyActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Challenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}