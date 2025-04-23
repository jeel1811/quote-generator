class Quote {
  final String id;
  final String content;
  final String author;
  final String category;
  final bool isFavorite;
  final bool isUserGenerated;
  final String? createdBy;
  final DateTime? createdAt;
  final bool? isPublic;

  Quote({
    required this.id,
    required this.content,
    required this.author,
    required this.category,
    this.isFavorite = false,
    this.isUserGenerated = false,
    this.createdBy,
    this.createdAt,
    this.isPublic,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['_id'] ?? json['id'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? 'Unknown',
      category:
          json['tags'] != null && json['tags'].isNotEmpty
              ? json['tags'][0]
              : (json['category'] ?? 'general'),
      isFavorite: json['isFavorite'] ?? false,
      isUserGenerated: json['isUserGenerated'] ?? false,
      createdBy: json['createdBy'],
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] is DateTime
                  ? json['createdAt']
                  : DateTime.parse(json['createdAt']))
              : null,
      isPublic: json['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author,
      'category': category,
      'isFavorite': isFavorite,
      'isUserGenerated': isUserGenerated,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'isPublic': isPublic,
    };
  }

  Quote copyWith({
    String? id,
    String? content,
    String? author,
    String? category,
    bool? isFavorite,
    bool? isUserGenerated,
    String? createdBy,
    DateTime? createdAt,
    bool? isPublic,
  }) {
    return Quote(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      isUserGenerated: isUserGenerated ?? this.isUserGenerated,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
