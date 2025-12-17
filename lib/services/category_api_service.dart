import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categoryPost.dart';

class CategoryApiService {
  CategoryApiService({http.Client? client}) : _client = client ?? http.Client();

  // Đảm bảo URL này khớp với CategoryApiController trong C#
  static const String _baseUrl =
      'https://fastaquaski68.conveyor.cloud/api/CategoryApi';

  final http.Client _client;

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json; charset=utf-8',
      };

  Uri _buildUri([String? path]) {
    final String base = path == null ? _baseUrl : '$_baseUrl/$path';
    return Uri.parse(base);
  }

  Future<List<CategoryPost>> fetchCategories() async {
    final response = await _client.get(_buildUri());
    _ensureSuccess(response);
    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return data
        .map((item) => CategoryPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryPost> fetchCategoryById(int id) async {
    final response = await _client.get(_buildUri('$id'));
    _ensureSuccess(response);
    return CategoryPost.fromJson(json.decode(response.body));
  }

  Future<CategoryPost> createCategory(CategoryPost category) async {
    final response = await _client.post(
      _buildUri(),
      headers: _headers,
      body: json.encode(category.toJson(includeId: false)),
    );
    _ensureSuccess(response);
    return CategoryPost.fromJson(json.decode(response.body));
  }

  Future<void> deleteCategory(int id) async {
    final response = await _client.delete(_buildUri('$id'));
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Category API Error ${response.statusCode}');
  }
}