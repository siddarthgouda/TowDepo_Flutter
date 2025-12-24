import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Data Models/user_profile_model.dart';
import '../config/app_config.dart';
import 'auth_service.dart';


class UserProfileService {
  static String get baseUrl => '${AppConfig.apiBaseUrl}/userprofiles';

  // Create headers with auth token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAccessToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Get current user's profile - with automatic creation if doesn't exist
  static Future<UserProfile> getCurrentUserProfile() async {
    try {
      // Check if user is logged in first
      final isLoggedIn = await AuthService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get user data from AuthService
      final userData = await AuthService.getUserData();
      final userId = userData['id'];

      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found');
      }

      print('🔍 Fetching user profile for ID: $userId');

      try {
        // Try to get existing profile
        final response = await http.get(
          Uri.parse('$baseUrl/$userId'),
          headers: await _getHeaders(),
        );

        print('📥 Response Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          return UserProfile.fromJson(responseData);
        } else if (response.statusCode == 404) {
          // Profile doesn't exist - create one automatically
          print('🆕 Profile not found, creating new profile...');
          return await _createDefaultProfile(userId, userData);
        } else {
          throw Exception('Failed to load user profile: ${response.statusCode}');
        }
      } catch (e) {
        // If there's an error, try to create a profile
        print('❌ Error fetching profile, creating new one: $e');
        return await _createDefaultProfile(userId, userData);
      }
    } catch (e) {
      print('❌ Error in getCurrentUserProfile: $e');
      rethrow;
    }
  }

  // Create a default profile with user data from AuthService
  static Future<UserProfile> _createDefaultProfile(String userId, Map<String, dynamic> userData) async {
    try {
      print('🔄 Creating default profile for user: $userId');

      // Split name into first and last name
      String firstName = '';
      String lastName = '';
      if (userData['name'] != null) {
        final nameParts = userData['name'].toString().split(' ');
        firstName = nameParts.first;
        lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }

      final newProfile = UserProfile(
        id: userId,
        personalInformation: PersonalInformation(
          firstName: firstName,
          lastName: lastName,
          email: userData['email'] ?? '',
        ),
        createdOn: DateTime.now(),
        updatedOn: DateTime.now(),
      );

      final createdProfile = await createUserProfile(newProfile);
      print('✅ Default profile created successfully');
      return createdProfile;
    } catch (e) {
      print('❌ Failed to create default profile: $e');
      // Return a local profile object even if creation fails
      return UserProfile(
        id: userId,
        personalInformation: PersonalInformation(
          firstName: userData['name']?.split(' ').first ?? 'User',
          lastName: userData['name']?.split(' ').length > 1 ? userData['name']?.split(' ').sublist(1).join(' ') : '',
          email: userData['email'] ?? '',
        ),
        createdOn: DateTime.now(),
        updatedOn: DateTime.now(),
      );
    }
  }

  // Create a new user profile
  static Future<UserProfile> createUserProfile(UserProfile userProfile) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _getHeaders(),
        body: jsonEncode(userProfile.toJson()),
      );

      print('📤 Create Profile Response: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return UserProfile.fromJson(responseData);
      } else {
        final errorBody = response.body;
        throw Exception('Failed to create user profile: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get user profile by ID
  static Future<UserProfile> getUserProfileById(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: await _getHeaders(),
      );

      print('📥 Get Profile Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return UserProfile.fromJson(responseData);
      } else if (response.statusCode == 404) {
        throw Exception('User profile not found');
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Update user profile by ID
  static Future<UserProfile> updateUserProfileById(String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$userId'),
        headers: await _getHeaders(),
        body: jsonEncode(updateData),
      );

      print('📝 Update Profile Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return UserProfile.fromJson(responseData);
      } else {
        throw Exception('Failed to update user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Update current user's profile
  static Future<UserProfile> updateCurrentUserProfile(Map<String, dynamic> updateData) async {
    try {
      final userData = await AuthService.getUserData();
      final userId = userData['id'];

      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found');
      }

      return await updateUserProfileById(userId, updateData);
    } catch (e) {
      throw Exception('Failed to update current user profile: $e');
    }
  }

  // Delete user profile by ID
  static Future<void> deleteUserProfileById(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get paginated user profiles
  static Future<Map<String, dynamic>> getPaginatedUserProfiles(Map<String, dynamic> filter, Map<String, dynamic> options) async {
    try {
      final queryParams = {
        ...filter,
        'page': options['page']?.toString() ?? '1',
        'limit': options['limit']?.toString() ?? '10',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profiles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Check if profile exists
  static Future<bool> checkProfileExists(String userId) async {
    try {
      await getUserProfileById(userId);
      return true;
    } catch (e) {
      return false;
    }
  }
}