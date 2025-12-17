class ProductPost {
  final int? id;
  final String? name;
  final double? price;
  final List<String>? images; // Đã chuyển sang List<String>
  final String? description;
  final int? categoryId; // Thêm categoryId

  const ProductPost({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.description,
    this.categoryId,
  });

  factory ProductPost.fromJson(Map<String, dynamic> json) {
    return ProductPost(
      id: json['id'] as int?,
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      // Xử lý nạp mảng chuỗi an toàn từ JSON
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : [],
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int?,
    );
  }

  ProductPost copyWith({
    int? id,
    String? name,
    double? price,
    List<String>? images,
    String? description,
    int? categoryId,
  }) {
    return ProductPost(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      images: images ?? this.images,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      'images': images, // Gửi mảng lên API
      'description': description,
      'categoryId': categoryId,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    // Không remove null nếu categoryId có thể là null, 
    // nhưng ở đây ta giữ nguyên logic cũ của bạn
    map.removeWhere((_, value) => value == null);
    return map;
  }
}