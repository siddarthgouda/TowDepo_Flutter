import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Data Models/product_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class CartItem {
  final String id;
  final String rawId;
  final String? productId;
  final Product? product;
  final String? variantId;
  int count;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItem({
    required this.id,
    required this.rawId,
    this.productId,
    this.product,
    this.variantId,
    required this.count,
    this.createdAt,
    this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    String id = '';
    String rawId = '';

    if (json['id'] != null && json['id'] is String && (json['id'] as String).isNotEmpty) {
      id = json['id'] as String;
    } else if (json['_id'] != null) {
      final _id = json['_id'];
      if (_id is Map && _id['\$oid'] != null) {
        rawId = _id['\$oid'] as String;
        id = rawId;
      } else if (_id is String) {
        rawId = _id;
        id = rawId;
      }
    }

    String? productId;
    Product? product;
    try {
      final prodField = json['product'];
      if (prodField != null) {
        if (prodField is Map<String, dynamic>) {
          final hasFullProductInfo = prodField.containsKey('title') || prodField.containsKey('mrp') || prodField.containsKey('SKU') || prodField.containsKey('_id');
          if (hasFullProductInfo) {
            try {
              product = Product.fromJson(Map<String, dynamic>.from(prodField));
              productId = product.id;
            } catch (_) {
              final pid = findProductId(prodField);
              if (pid.isNotEmpty) productId = pid;
            }
          } else {
            final pid = findProductId(prodField);
            if (pid.isNotEmpty) {
              productId = pid;
            } else if (prodField.containsKey(r'$oid') && prodField[r'$oid'] is String) {
              productId = prodField[r'$oid'] as String;
            } else if (prodField['id'] is String) {
              productId = prodField['id'] as String;
            }
          }
        } else if (prodField is String) {
          productId = prodField;
        }
      }
    } catch (_) {
      product = null;
    }

    String? variantId;
    try {
      if (json['variantId'] != null && json['variantId'] is String) {
        variantId = json['variantId'] as String;
      } else if (json['product'] is Map) {
        final prodMap = Map<String, dynamic>.from(json['product']);
        if (prodMap['variantId'] != null && prodMap['variantId'] is String) {
          variantId = prodMap['variantId'] as String;
        }
      }
    } catch (_) {
      variantId = null;
    }

    final countVal = json['count'];
    int count = 0;
    if (countVal is int) {
      count = countVal;
    } else if (countVal is String) {
      count = int.tryParse(countVal) ?? 0;
    } else if (countVal is double) {
      count = countVal.toInt();
    }

    return CartItem(
      id: id,
      rawId: rawId,
      productId: productId,
      product: product,
      variantId: variantId,
      count: count,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'count': count,
      if (productId != null) 'productId': productId,
      if (product != null)
        'product': {
          'id': product!.id,
          'title': product!.title,
          'mrp': product!.mrp,
          'discount': product!.discount,
          'brand': product!.brand?.name ?? product!.brand?.id ?? 'N/A',
          'images': product!.images?.map((e) => e.src).toList() ?? [],
        }
      else
        'product': null,
    };

    if (variantId != null) {
      map['variantId'] = variantId;
    }

    return map;
  }
}

class CartService {
  // ✅ FIXED: Use ApiService.getHeaders() for automatic token refresh and debugging
  static Future<Map<String, String>> _headers() async {
    return await ApiService.getHeaders();
  }

  static String _base() {
    return ApiService.baseUrl;
  }

  /// Add product to cart
  static Future<CartItem> addToCart(
      Product product, {
        required String variantId,
        int quantity = 1,
      }) async {
    final productId = product.id;
    if (productId == null || productId.isEmpty) {
      throw Exception('Product id is missing');
    }

    final uri = Uri.parse('${_base()}/cart');

    print('🛒 ADD TO CART DEBUG:');
    print('   URL: $uri');
    print('   Product ID: $productId');
    print('   Variant ID: $variantId');
    print('   Quantity: $quantity');

    final body = jsonEncode({
      'product': {
        'id': productId,
        'title': product.title,
        'mrp': product.mrp,
        'discount': product.discount,
        'brand': product.brand?.name ?? 'N/A',
        'images': product.images?.map((i) => i.src).toList(),
      },
      'variantId': variantId,
      'quantity': quantity,
    });

    print('   Request Body: $body');

    try {
      final headers = await _headers();
      print('   Headers: $headers');

      final resp = await http.post(uri, headers: headers, body: body);

      print('   Response Status: ${resp.statusCode}');
      print('   Response Body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return CartItem.fromJson(jsonDecode(resp.body));
      } else {
        throw Exception('Failed to add to cart: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }

  /// Get cart items for current user
  static Future<List<CartItem>> fetchCartItems({int limit = 100}) async {
    final uri = Uri.parse('${_base()}/cart?limit=$limit');

    print('🛒 FETCH CART DEBUG:');
    print('   URL: $uri');

    try {
      final headers = await _headers();
      print('   Headers: $headers');

      final resp = await http.get(uri, headers: headers);

      print('   Response Status: ${resp.statusCode}');
      print('   Response Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['results'] is List) {
          return (decoded['results'] as List)
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (decoded is List) {
          return (decoded as List)
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          return [];
        }
      } else if (resp.statusCode == 401) {
        await AuthService.clearAuthData();
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch cart: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }

  /// Update cart item count
  static Future<void> updateCartCount(String cartId, int count) async {
    final uri = Uri.parse('${_base()}/cart/$cartId');

    print('🛒 UPDATE CART DEBUG:');
    print('   URL: $uri');
    print('   Cart ID: $cartId');
    print('   Count: $count');

    final body = jsonEncode({'count': count});

    try {
      final headers = await _headers();
      final resp = await http.put(uri, headers: headers, body: body);

      print('   Response Status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        return;
      } else if (resp.statusCode == 401) {
        await AuthService.clearAuthData();
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to update cart: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }

  /// Delete cart item
  static Future<void> deleteCartItem(String cartId) async {
    final uri = Uri.parse('${_base()}/cart/$cartId');

    print('🛒 DELETE CART DEBUG:');
    print('   URL: $uri');
    print('   Cart ID: $cartId');

    try {
      final headers = await _headers();
      final resp = await http.delete(uri, headers: headers);

      print('   Response Status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        return;
      } else if (resp.statusCode == 401) {
        await AuthService.clearAuthData();
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to delete cart: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      print('   ❌ Exception: $e');
      rethrow;
    }
  }
}