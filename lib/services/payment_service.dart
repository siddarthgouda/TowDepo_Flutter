import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class PaymentService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String get _baseUrl => AppConfig.apiBaseUrl;

  /// Create Razorpay order on the backend
  static Future<Map<String, dynamic>> createPaymentOrder({
    required double amount,
    required String orderId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payments/create-order');
      final body = jsonEncode({
        'amount': amount,
        'orderId': orderId,
      });

      debugPrint('🔄 Creating payment order: $uri');
      debugPrint('📦 Request body: ${jsonEncode({
        'amount': amount,
        'orderId': orderId,
      })}');

      final response = await http.post(
        uri,
        headers: await _headers(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Your backend returns data in a 'data' field
        if (decoded['data'] != null) {
          debugPrint('✅ Payment order created successfully');
          return Map<String, dynamic>.from(decoded['data']);
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('${errorBody['message']} (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Error creating payment order: $e');
      rethrow;
    }
  }

  /// Verify payment on backend
  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
    required Map<String, dynamic> selectedAddress,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/payment/verify');
      final body = jsonEncode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'orderId': orderId,
        'selectedAddress': selectedAddress,
        'cartItems': cartItems,
      });

      debugPrint('🔄 Verifying payment: $uri');
      debugPrint('📦 Verification data sent');

      final response = await http.post(
        uri,
        headers: await _headers(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Verification response status: ${response.statusCode}');
      debugPrint('📡 Verification response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('✅ Payment verified successfully');
        return Map<String, dynamic>.from(decoded);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('${errorBody['message']} (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
      rethrow;
    }
  }
}