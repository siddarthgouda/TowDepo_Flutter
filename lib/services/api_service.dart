import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static int _retryCount = 0;
  static const int _maxRetries = 1;

  // Helper method to get headers with auth token
  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('✅ Authorization header added with token');
      } else {
        print('❌ No token available for authorization');
      }
    }

    return headers;
  }

  // Enhanced request handler with token refresh
  static Future<http.Response> _makeRequest(
      Future<http.Response> Function() request, {
        bool retryOnAuthError = true,
      }) async {
    try {
      final response = await request();

      // If token is expired, try to refresh and retry
      if (response.statusCode == 401 && retryOnAuthError && _retryCount < _maxRetries) {
        print('🔐 401 Received - Attempting token refresh...');
        _retryCount++;
        final refreshSuccess = await _refreshToken();
        _retryCount = 0;

        if (refreshSuccess) {
          print('✅ Token refreshed, retrying request...');
          return await request();
        } else {
          print('❌ Token refresh failed, logging out...');
          await AuthService.clearTokens();
          throw Exception('Session expired. Please login again.');
        }
      }

      return response;
    } catch (e) {
      _retryCount = 0;
      rethrow;
    }
  }

  // Token refresh method - matches your backend endpoint
  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No refresh token available');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-tokens'), // Your backend endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await AuthService.saveTokens(responseData);
        return true;
      } else {
        await AuthService.clearTokens();
        return false;
      }
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    }
  }

  // Login API
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _makeRequest(
          () async => http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: await getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ),
        retryOnAuthError: false,
    );

    return _handleResponse(response);
  }

  // Register API
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _makeRequest(
          () async => http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: await getHeaders(includeAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    ),
        retryOnAuthError: false,
    );

    return _handleResponse(response);
  }

  // Get user profile using token
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _makeRequest(
          () async => http.get(
          Uri.parse('$baseUrl/auth/'),
          headers: await getHeaders(),
    ),
    );

    return _handleResponse(response);
  }

  // Logout API
  static Future<void> logout(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await getHeaders(),
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Forgot Password API
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Google Login API
  static Future<Map<String, dynamic>> googleLogin(String googleToken) async {
    final response = await _makeRequest(
          () async => http.post(
          Uri.parse('$baseUrl/auth/google-login'),
          headers: await getHeaders(includeAuth: false),
      body: jsonEncode({
        'token': googleToken,
      }),
    ),
        retryOnAuthError: false,
    );

    return _handleResponse(response);
  }

  // OTP Login API
  static Future<Map<String, dynamic>> otpLogin(String email) async {
    final response = await _makeRequest(
          () async => http.post(
          Uri.parse('$baseUrl/auth/otpLogin'),
          headers: await getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
      }),
    ),
        retryOnAuthError: false,
    );

    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final responseBody = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      final errorMessage = responseBody['message'] ??
          responseBody['error'] ??
          'Something went wrong (Status: ${response.statusCode})';
      throw Exception(errorMessage);
    }
  }
}