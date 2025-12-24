import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Data Models/user_profile_model.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if user is logged in using AuthService
      final isLoggedIn = await AuthService.isLoggedIn();
      print('🔐 User logged in: $isLoggedIn');

      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view your profile';
        });
        return;
      }

      // Get user data from AuthService for debugging
      final userData = await AuthService.getUserData();
      print('👤 Auth User Data: $userData');

      final userProfile = await UserProfileService.getCurrentUserProfile();
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
      print('✅ Profile loaded successfully');

    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile: $e';
      });
    }
  }

  Future<void> _updateProfileField(String field, String value) async {
    try {
      setState(() {
        _isUpdating = true;
      });

      final updateData = {
        'Personal_Information': {
          field: value,
        }
      };

      final updatedProfile = await UserProfileService.updateCurrentUserProfile(updateData);
      setState(() {
        _userProfile = updatedProfile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        // TODO: Upload image to your backend
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToEditProfile() {
    _showEditProfileDialog();
  }

  Future<void> _logout() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken != null) {
        // You can call your logout API if needed
      }

      await AuthService.clearAuthData();

      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      // Even if logout fails, clear local data
      await AuthService.clearAuthData();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  String _getDisplayName() {
    if (_userProfile == null) return 'Loading...';
    final name = _userProfile!.personalInformation.fullName;
    return name.isNotEmpty ? name : 'User';
  }

  String _getEmail() {
    if (_userProfile == null) return 'Loading...';
    return _userProfile!.personalInformation.email ?? 'No email provided';
  }

  String _getUserSince() {
    if (_userProfile?.createdOn == null) return 'Recently joined';
    final now = DateTime.now();
    final difference = now.difference(_userProfile!.createdOn!);

    if (difference.inDays < 1) return 'Today';
    if (difference.inDays == 1) return '1 day ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    return '${(difference.inDays / 30).floor()} months ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_userProfile != null)
            IconButton(
              icon: _isUpdating
                  ? const CircularProgressIndicator.adaptive(strokeWidth: 2)
                  : const Icon(Icons.edit_outlined),
              onPressed: _isUpdating ? null : _navigateToEditProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: ListView(
          children: [
            _buildProfileHeader(),
            _buildAccountInfoSection(),
            _buildSettingsSection(),
            _buildSupportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(
                    _profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                      : _buildDefaultAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getDisplayName(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getEmail(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Text(
              'Member since ${_getUserSince()}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_userProfile?.personalInformation.bio != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _userProfile!.personalInformation.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return _buildSection(
      title: 'Account Information',
      children: [
        _buildInfoTile(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: _getDisplayName(),
          onTap: _navigateToEditProfile,
        ),
        _buildInfoTile(
          icon: Icons.email_outlined,
          title: 'Email Address',
          subtitle: _getEmail(),
          onTap: () {
            _showEditDialog('Email', _getEmail(), (newValue) {
              _updateProfileField('Email', newValue);
            });
          },
        ),
        _buildInfoTile(
          icon: Icons.phone_outlined,
          title: 'Phone Number',
          subtitle: _userProfile?.personalInformation.phoneNumber ?? 'Not set',
          onTap: () {
            _showEditDialog('Phone Number',
                _userProfile?.personalInformation.phoneNumber ?? '',
                    (newValue) {
                  _updateProfileField('phoneNumber', newValue);
                });
          },
        ),
        _buildInfoTile(
          icon: Icons.location_on_outlined,
          title: 'Address',
          subtitle: _userProfile?.manageAddress?.currentAddress ?? 'No address saved',
          onTap: () {
            _showAddressDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return _buildSection(
      title: 'Settings',
      children: [
        _buildInfoTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage your notifications',
          onTap: () {
            // TODO: Navigate to notifications
          },
        ),
        _buildInfoTile(
          icon: Icons.security_outlined,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            // TODO: Navigate to privacy settings
          },
        ),
        _buildInfoTile(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'English (US)',
          onTap: () {
            // TODO: Show language selection
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'Support',
      children: [
        _buildInfoTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'Get help with your account',
          onTap: () {
            // TODO: Navigate to help center
          },
        ),
        _buildInfoTile(
          icon: Icons.support_agent_outlined,
          title: 'Customer Support',
          subtitle: '24/7 customer support',
          onTap: () {
            // TODO: Navigate to customer support
          },
        ),
        _buildInfoTile(
          icon: Icons.info_outline,
          title: 'About Us',
          subtitle: 'Learn more about our company',
          onTap: () {
            // TODO: Navigate to about us
          },
        ),
        _buildInfoTile(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: _showLogoutDialog,
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: isLogout ? Colors.red : Theme.of(context).primaryColor,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isLogout ? Colors.red : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: isLogout ? Colors.red.withOpacity(0.7) : Colors.grey,
            ),
          ),
          trailing: isLogout ? null : Icon(
            Icons.chevron_right,
            color: isLogout ? Colors.red : Colors.grey,
          ),
          onTap: onTap,
        ),
        if (!isLogout)
          const Divider(height: 1, indent: 16),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (_errorMessage!.contains('Please login'))
              ElevatedButton(
                onPressed: _navigateToLogin,
                child: const Text('Go to Login'),
              ),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToLogin() async {
    // Push the LoginPage and wait for result (expecting `true` when login succeeds)
    final loginResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );

    // If user logged in successfully, reload profile
    if (loginResult == true) {
      // small delay so any auth tokens are stored before fetching
      await Future.delayed(const Duration(milliseconds: 250));
      await _loadUserProfile();
    }
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField('First Name', 'firstName', _userProfile?.personalInformation.firstName ?? ''),
                _buildEditField('Last Name', 'lastName', _userProfile?.personalInformation.lastName ?? ''),
                _buildEditField('Bio', 'bio', _userProfile?.personalInformation.bio ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField(String label, String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _updateProfileField(field, controller.text.trim());
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  void _showEditDialog(String field, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your $field',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onSave(controller.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Address Information'),
          content: Text(_userProfile?.manageAddress?.currentAddress ?? 'No address saved'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}