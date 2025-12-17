class CategoryPost {
  final int? id;
  final String? name;

  const CategoryPost({
    required this.id,
    required this.name,
  });

  factory CategoryPost.fromJson(Map<String, dynamic> json) {
    return CategoryPost(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }

  CategoryPost copyWith({
    int? id,
    String? name,
  }) {
    return CategoryPost(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'name': name,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }
}