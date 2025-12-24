import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Data Models/product_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class WishlistItem {
  final String id;
  final String productId;
  final String title;
  final String? image;
  final int? mrp;
  final String? discount;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.title,
    this.image,
    this.mrp,
    this.discount,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    String pid = '';
    final prod = json['product'];

    if (prod is String) {
      pid = prod;
    }
    else if (prod is Map) {
      if (prod['_id'] is String) {
        pid = prod['_id'];
      }
      else if (prod['_id'] is Map && prod['_id']['\$oid'] is String) {
        pid = prod['_id']['\$oid'];
      }
      else if (prod['id'] is String) {
        pid = prod['id'];
      }
    }

    return WishlistItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      productId: pid,
      title: json['title'] ?? (prod is Map ? (prod['title'] ?? '') : ''),
      image: json['image'] ?? (prod is Map ? (prod['images'] != null && prod['images'] is List && prod['images'].isNotEmpty ? prod['images'][0] : null) : null),
      mrp: json['mrp'] is int ? json['mrp'] : (json['mrp'] is String ? int.tryParse(json['mrp']) : null),
      discount: json['discount']?.toString(),
    );
  }
}

class WishlistService {
  // ✅ FIXED: Use ApiService.getHeaders() for automatic token refresh and debugging
  static Future<Map<String, String>> _headers() async {
    return await ApiService.getHeaders();
  }

  static String _base() {
    return ApiService.baseUrl;
  }

  // Add to wishlist
  static Future<WishlistItem> addToWishlist(Product product) async {
    if (product.id.isEmpty) throw Exception('product.id is empty for product ${product.title}');

    final uri = Uri.parse('${_base()}/wishlist');

    print('❤️ ADD TO WISHLIST DEBUG:');
    print('   URL: $uri');
    print('   Product ID: ${product.id}');

    final body = jsonEncode({
      'product': product.id,
      'title': product.title,
      'mrp': product.mrp ?? 0,
      'discount': product.discount ?? '0',
      'brand': product.brand?.name ?? 'N/A',
      'image': product.firstImageUrl,
    });

    try {
      final headers = await _headers();
      print('   Headers: $headers');

      final resp = await http.post(uri, headers: headers, body: body);

      print('   Response Status: ${resp.statusCode}');
      print('   Response Body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return WishlistItem.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to add wishlist: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }

  // Remove by product id
  static Future<void> removeByProductId(String productId) async {
    final uri = Uri.parse('${_base()}/wishlist/product/$productId');

    print('❤️ REMOVE FROM WISHLIST DEBUG:');
    print('   URL: $uri');
    print('   Product ID: $productId');

    try {
      final headers = await _headers();
      final resp = await http.delete(uri, headers: headers);

      print('   Response Status: ${resp.statusCode}');

      if (resp.statusCode == 200) return;
      if (resp.statusCode == 401) {
        await AuthService.clearAuthData();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to remove wishlist: ${resp.statusCode} ${resp.body}');
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }

  // Fetch wishlist
  static Future<List<WishlistItem>> fetchWishlist({int limit = 100}) async {
    final uri = Uri.parse('${_base()}/wishlist?limit=$limit');

    print('❤️ FETCH WISHLIST DEBUG:');
    print('   URL: $uri');

    try {
      final headers = await _headers();
      print('   Headers: $headers');

      final resp = await http.get(uri, headers: headers);

      print('   Response Status: ${resp.statusCode}');
      print('   Response Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> list = [];
        if (decoded is Map && decoded['results'] is List) list = decoded['results'];
        else if (decoded is List) list = decoded;
        return list.map((e) => WishlistItem.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (resp.statusCode == 401) {
        await AuthService.clearAuthData();
        throw Exception('Unauthorized. Please login.');
      } else {
        throw Exception('Failed to fetch wishlist: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }

  // Check if product is in wishlist
  static Future<bool> isInWishlist(String productId) async {
    final items = await fetchWishlist(limit: 500);
    return items.any((i) => i.productId == productId);
  }
}