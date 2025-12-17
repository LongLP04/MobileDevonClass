import 'dart:convert';
import '../models/productPost.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MarketScreen extends StatelessWidget {
const MarketScreen({super.key});

  Future<List<productPost>> fetchPosts() async {
    final String baseUrl= 'https://rightredbox94.conveyor.cloud/api/ProductApi';
    final response= await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => productPost.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Screen'),
      ),
      body: FutureBuilder<List<productPost>>(
        future: fetchPosts(),  // Fetch data from the API
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products available.'));
          } else {
            List<productPost> posts = snapshot.data!;

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                productPost post = posts[index];
                return ListTile(
                  leading: Image.network(post.image ?? ''),
                  title: Text(post.name ?? 'No name'),
                  subtitle: Text(post.description ?? 'No description'),
                  trailing: Text('${post.price} VND'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
