import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Data Models/product_model.dart';
import '../config/app_config.dart';

class ApiService {
  static Future<List<Product>> fetchNearbyProducts(double lat, double lng, [double radius = 10]) async {
    final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/v1/product/nearby?lat=$lat&lng=$lng&radius=$radius');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch nearby products: ${response.statusCode}');
    }
  }
}
