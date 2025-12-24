import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences once
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> clearTokens() async {
    final prefs = await _getPrefs();

    print('🗑️ Clearing all tokens and user data...');

    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');

    await prefs.reload();

    print('✅ All tokens cleared successfully');
  }

  // For compatibility with existing code
  static Future<void> clearAuthData() async {
    await clearTokens();
  }

  // Updated to match your backend structure: {user: {}, tokens: {access: {token: ''}, refresh: {token: ''}}}
  static Future<void> saveTokens(Map<String, dynamic> response) async {
    final prefs = await _getPrefs();

    print('💾 Saving tokens from backend response...');
    print('📦 Response keys: ${response.keys}');

    String? accessToken;
    String? refreshToken;

    // ✅ YOUR BACKEND STRUCTURE: {user: {}, tokens: {access: {token: ''}, refresh: {token: ''}}}
    if (response['tokens'] != null && response['tokens'] is Map) {
      final tokens = response['tokens'];
      print('🔑 Tokens structure: ${tokens.keys}');

      // Extract access token from tokens.access.token
      if (tokens['access'] != null && tokens['access'] is Map) {
        accessToken = tokens['access']['token'];
        print('✅ Found access token: ${accessToken != null ? "EXISTS" : "NULL"}');
      }

      // Extract refresh token from tokens.refresh.token
      if (tokens['refresh'] != null && tokens['refresh'] is Map) {
        refreshToken = tokens['refresh']['token'];
        print('✅ Found refresh token: ${refreshToken != null ? "EXISTS" : "NULL"}');
      }
    }

    // Save tokens to SharedPreferences
    if (accessToken != null) {
      await prefs.setString('accessToken', accessToken);
      print('🔑 Access token saved (${accessToken.length} chars)');
    } else {
      print('❌ No access token found!');
    }

    if (refreshToken != null) {
      await prefs.setString('refreshToken', refreshToken);
      print('🔄 Refresh token saved (${refreshToken.length} chars)');
    } else {
      print('⚠️ No refresh token found');
    }

    await prefs.setBool('isLoggedIn', true);
    print('✅ Login status set to true');
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await _getPrefs();

    print('👤 Saving user data: ${user.keys}');

    // Handle different possible user field names
    final name = user['name'] ?? user['username'] ?? user['fullName'] ?? '';
    final email = user['email'] ?? '';
    final id = user['id']?.toString() ?? user['_id']?.toString() ?? '';

    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userId', id);

    print('✅ User data saved - Name: $name, Email: $email, ID: $id');
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await _getPrefs();
    return {
      'name': prefs.getString('userName') ?? '',
      'email': prefs.getString('userEmail') ?? '',
      'id': prefs.getString('userId') ?? '',
    };
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final accessToken = await getAccessToken();

    final result = isLoggedIn && (accessToken != null && accessToken.isNotEmpty);
    print('🔐 isLoggedIn check: $result (flag: $isLoggedIn, token: ${accessToken != null ? "exists" : "null"})');

    return result;
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _getPrefs();
    return prefs.getString('accessToken');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString('refreshToken');
  }

  // Debug method to check token status
  static Future<Map<String, dynamic>> getTokenStatus() async {
    final prefs = await _getPrefs();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    return {
      'hasAccessToken': accessToken != null && accessToken.isNotEmpty,
      'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
      'isLoggedInFlag': isLoggedIn,
      'accessTokenLength': accessToken?.length ?? 0,
      'refreshTokenLength': refreshToken?.length ?? 0,
    };
  }
}