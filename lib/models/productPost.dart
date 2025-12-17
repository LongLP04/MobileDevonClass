class productPost {
  const productPost({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
  });

  final int? id;
  final String? name;
  final double? price;
  final String? image;
  final String? description;

  factory productPost.fromJson(Map<String, dynamic> json) {
    return productPost(
      id: json['id'] as int?,
      name: json['name'] as String?,
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as num?)?.toDouble(),
      image: json['image'] as String?,
      description: json['description'] as String?,
    );
  }

  productPost copyWith({
    int? id,
    String? name,
    double? price,
    String? image,
    String? description,
  }) {
    return productPost(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      'image': image,
      'description': description,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    map.removeWhere((_, value) => value == null);
    return map;
  }
}

