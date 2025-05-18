class ArtikelModel {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String? content;
  final DateTime? createdAt;

  ArtikelModel({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    this.content,
    this.createdAt,
  });

  factory ArtikelModel.fromJson(Map<String, dynamic> json) {
    return ArtikelModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      content: json['content'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'content': content,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
} 