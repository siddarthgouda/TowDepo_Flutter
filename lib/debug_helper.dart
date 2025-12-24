import 'package:shared_preferences/shared_preferences.dart';

class DebugHelper {
  static Future<void> printAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();

    print('🔐 === AUTH DEBUG INFO ===');
    print('📱 isLoggedIn: ${prefs.getBool('isLoggedIn')}');

    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    print('🔑 Access Token: ${accessToken != null ? 'EXISTS (${accessToken.length} chars)' : 'NULL'}');
    print('🔄 Refresh Token: ${refreshToken != null ? 'EXISTS (${refreshToken.length} chars)' : 'NULL'}');

    if (accessToken != null) {
      print('📋 Access Token Preview: ${accessToken.substring(0, min(50, accessToken.length))}...');
    }

    print('👤 User Data:');
    print('   - Name: ${prefs.getString('userName')}');
    print('   - Email: ${prefs.getString('userEmail')}');
    print('   - ID: ${prefs.getString('userId')}');
    print('🔚 === END DEBUG INFO ===');
  }

  static int min(int a, int b) => a < b ? a : b;
}