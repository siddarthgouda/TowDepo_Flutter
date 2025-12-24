import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../Data Models/address.dart';
import 'auth_service.dart';

class AddressService {
  static String get baseUrl => "${AppConfig.apiBaseUrl}/address";

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Address>> fetchAddresses({int limit = 100, int page = 1}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl?limit=$limit&page=$page');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      final List rawList = body is List ? body : (body['results'] ?? body['data'] ?? body['docs'] ?? []);
      return rawList.map((e) => Address.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load addresses: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<Address> createAddress(Address a) async {
    final headers = await _authHeaders();
    final resp = await http.post(Uri.parse(baseUrl), headers: headers, body: json.encode(a.toJson()));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      return Address.fromJson(json.decode(resp.body));
    } else {
      throw Exception('Failed to create address: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<Address> updateAddress(String id, Address a) async {
    final headers = await _authHeaders();
    final resp = await http.patch(Uri.parse('$baseUrl/$id'), headers: headers, body: json.encode(a.toJson()));
    if (resp.statusCode == 200) {
      return Address.fromJson(json.decode(resp.body));
    } else {
      throw Exception('Failed to update address: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> deleteAddress(String id) async {
    final headers = await _authHeaders();
    final resp = await http.delete(Uri.parse('$baseUrl/$id'), headers: headers);
    if (resp.statusCode == 200 || resp.statusCode == 204) return;
    throw Exception('Failed to delete address: ${resp.statusCode} ${resp.body}');
  }
}
