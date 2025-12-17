import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/productPost.dart';

class ProductApiService {
  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  // Đảm bảo URL này khớp với URL của API bạn đang chạy
  static const String _baseUrl =
      'https://fastaquaski68.conveyor.cloud/api/ProductApi';

  final http.Client _client;

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json; charset=utf-8',
      };

  Uri _buildUri([String? path, Map<String, String>? query]) {
    final String base = path == null ? _baseUrl : '$_baseUrl/$path';
    final uri = Uri.parse(base);
    if (query == null) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query,
    });
  }

  Future<List<ProductPost>> fetchProducts() async {
    final response = await _client.get(_buildUri());
    return _decodeList(response);
  }

  Future<ProductPost> fetchProductById(int id) async {
    final response = await _client.get(_buildUri('$id'));
    return _decodeObject(response);
  }

  Future<ProductPost> createProduct(ProductPost product) async {
    final response = await _client.post(
      _buildUri(),
      headers: _headers,
      body: json.encode(product.toJson(includeId: false)),
    );
    return _decodeObject(response);
  }

  Future<ProductPost> updateProduct(int id, ProductPost product) async {
    final response = await _client.put(
      _buildUri('$id'),
      headers: _headers,
      body: json.encode(product.toJson()),
    );
    if (response.body.trim().isEmpty) {
      _ensureSuccess(response);
      return product.copyWith(id: id);
    }
    return _decodeObject(response);
  }

  Future<void> deleteProduct(int id) async {
    final response = await _client.delete(_buildUri('$id'));
    _ensureSuccess(response);
  }

  // --- Logic Search được giữ nguyên ---
  Future<List<ProductPost>> searchProductsByName(String keyword) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) return [];

    final lowerKeyword = cleanKeyword.toLowerCase();
    final attempts = <Future<List<ProductPost>> Function()>[
      () => _attemptRemoteSearch(
            _buildUri('search', {'name': cleanKeyword}),
            lowerKeyword,
          ),
      () => _attemptRemoteSearch(
            _buildUri('search/${Uri.encodeComponent(cleanKeyword)}'),
            lowerKeyword,
          ),
    ];

    for (final attempt in attempts) {
      try {
        final results = await attempt();
        if (results.isNotEmpty) return results;
      } catch (_) {}
    }

    final fallback = await fetchProducts();
    return _filterByKeyword(fallback, lowerKeyword);
  }

  List<ProductPost> _decodeList(http.Response response) {
    _ensureSuccess(response);
    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return data
        .map((item) => ProductPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  ProductPost _decodeObject(http.Response response) {
    _ensureSuccess(response);
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    return ProductPost.fromJson(data);
  }

  Future<List<ProductPost>> _attemptRemoteSearch(
    Uri uri,
    String lowerKeyword,
  ) async {
    final response = await _client.get(uri);
    final data = _decodeList(response);
    return _filterByKeyword(data, lowerKeyword);
  }

  List<ProductPost> _filterByKeyword(
    List<ProductPost> products,
    String lowerKeyword,
  ) {
    if (lowerKeyword.isEmpty) return products;
    return products
        .where(
          (product) => (product.name ?? '')
              .toLowerCase()
              .contains(lowerKeyword),
        )
        .toList();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
      'Server error ${response.statusCode}: ${response.body}',
    );
  }
}