import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../Data Models/product_model.dart';
import '../config/app_config.dart';

class ProductService {
  static String _baseUrl() {
    final raw = AppConfig.apiBaseUrl ?? '';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  // Recursively search for the first List anywhere inside `node`
  static List<dynamic>? _findFirstList(dynamic node) {
    if (node == null) return null;
    if (node is List) return node;
    if (node is Map) {
      for (final value in node.values) {
        final found = _findFirstList(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  // Try to turn `body` into a List<Product> by searching for list and also trying common keys.
  static List<Product> _parseProductsDynamic(dynamic body) {
    if (body == null) return <Product>[];

    List<dynamic>? listCandidate;

    // If it's already a list of objects
    if (body is List) {
      listCandidate = body;
    } else if (body is Map) {
      // common keys
      final keys = ['docs', 'data', 'items', 'results', 'products'];
      for (final k in keys) {
        if (body[k] is List) {
          listCandidate = body[k] as List<dynamic>;
          break;
        }
      }
      // recursive search if still not found
      listCandidate ??= _findFirstList(body);
    }

    if (listCandidate == null) return <Product>[];

    final parsed = <Product>[];
    for (var i = 0; i < listCandidate.length; i++) {
      final item = listCandidate[i];
      try {
        if (item is Map<String, dynamic>) {
          parsed.add(Product.fromJson(item));
        } else if (item is Map) {
          // convert to Map<String, dynamic>
          parsed.add(Product.fromJson(Map<String, dynamic>.from(item)));
        } else {
          // not a map — log and skip
          debugPrint(
              'ApiService.parse: skipping non-object item at index $i -> $item');
        }
      } catch (e, st) {
        // Log the raw item that failed to parse so you can inspect its fields (esp _id/id)
        try {
          final raw = item is Map || item is List ? jsonEncode(item) : item
              .toString();
          debugPrint(
              'ApiService.parse: failed to parse product at index $i. error: $e\nraw item: $raw\n$st');
        } catch (_) {
          debugPrint(
              'ApiService.parse: failed to parse product at index $i and could not encode raw item. error: $e\n$st');
        }
        // continue parsing others
      }
    }

    return parsed;
  }

  static Future<Map<String, dynamic>> _getRaw(String path,
      {Map<String, String>? extraHeaders}) async {
    final base = _baseUrl();
    final uri = Uri.parse('$base$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (extraHeaders != null) ...extraHeaders
    };

    final resp = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 15));
    final body = resp.body ?? '';
    final snippet = body.length > 8000 ? '${body.substring(0, 8000)}... (truncated)' : body;
    debugPrint('ApiService GET $uri -> ${resp.statusCode}\nHeaders: ${resp
        .headers}\nBody snippet:\n$snippet');
    return {'status': resp.statusCode, 'body': body};
  }

  /// Fetch all products (tries /product path).
  static Future<List<Product>> fetchAllProducts({
    int? page,
    int? limit,
    Map<String, String>? extraHeaders,
  }) async {
    final query = <String, String>{
      if (page != null) 'page': page.toString(),
      if (limit != null) 'limit': limit.toString(),
    };

    final queryStr = query.isNotEmpty
        ? '?' + query.entries.map((e) => '${e.key}=${e.value}').join('&')
        : '';

    final path = '/product$queryStr';

    final raw = await _getRaw(path, extraHeaders: extraHeaders);
    final status = raw['status'] as int;
    final body = raw['body'] as String;

    // SUCCESS CASE
    if (status >= 200 && status < 300) {
      dynamic decoded;

      try {
        decoded = jsonDecode(body);

        // For debugging small JSON
        if (kDebugMode) {
          if (body.length <= 4000) {
            debugPrint('ApiService.fetchAllProducts decoded JSON:\n$decoded');
          } else {
            debugPrint('ApiService.fetchAllProducts decoded JSON (big JSON)');
          }
        }
      } catch (e) {
        throw Exception('Invalid JSON received: $e');
      }

      // Parse to Product list and return
      final parsed = _parseProductsDynamic(decoded);
      debugPrint("fetchAllProducts → parsed ${parsed.length} products");

      return parsed;
    }

    // FAILURE CASE
    throw Exception('HTTP $status\nBody: $body');
  }


// resilient fetchProductById — paste into lib/services/api_service.dart
  static Future<Product> fetchProductById(String id,
      {Map<String, String>? extraHeaders}) async {
    final raw = await _getRaw('/product/$id', extraHeaders: extraHeaders);
    final status = raw['status'] as int;
    final body = raw['body'] as String;

    // Success: parse and return product
    if (status >= 200 && status < 300) {
      try {
        final decoded = jsonDecode(body);
        Map<String, dynamic>? obj;
        if (decoded is Map) {
          if (decoded['result'] is Map) {
            obj = Map<String, dynamic>.from(decoded['result']);
          } else if (decoded['data'] is Map) {
            obj = Map<String, dynamic>.from(decoded['data']);
          } else {
            obj = Map<String, dynamic>.from(decoded);
          }
        }
        if (obj == null) throw Exception('Unexpected product response shape');
        return Product.fromJson(obj);
      } catch (e) {
        throw Exception('Failed to parse product JSON: $e');
      }
    }

    // If backend responded with 400 about populate, return a minimal Product instead of throwing.
    if (status == 400 && body.contains('storeId')) {
      debugPrint(
          'ApiService.fetchProductById: backend populate error for storeId -> returning minimal Product(id=$id)');
      return Product.withId(id);
    }

    // For other 4xx responses return minimal Product (don't block checkout).
    if (status >= 400 && status < 500) {
      debugPrint(
          'ApiService.fetchProductById: HTTP $status (4xx). Returning minimal Product(id=$id). Body snippet: ${body
              .length > 200 ? body.substring(0, 200) + "..." : body}');
      return Product.withId(id);
    }

    // For 5xx and others, throw so developer notices
    throw Exception('HTTP $status\nBody: $body');
  }
}