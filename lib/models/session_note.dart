class SessionNote {
  const SessionNote({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  factory SessionNote.fromJson(Map<String, dynamic> json) {
    return SessionNote(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
