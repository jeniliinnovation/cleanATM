import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _name = 'Loading...';
  String _phone = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiService.getUserProfile();
      if (mounted) {
        if (res['success'] == true) {
          final data = res['data'];
          setState(() {
            _name = data['name'] ?? 'User';
            _phone = data['mobile'] ?? '';
            _email = data['email'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    await ApiService.clearToken();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                       const CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.person, size: 60, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (_phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_phone, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                      if (_email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_email, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildProfileItem(Icons.person_outline, 'Edit Profile', onTap: () {}),
                _buildProfileItem(Icons.lock_outline, 'Change Password', onTap: () {}),
                _buildProfileItem(Icons.assignment_outlined, 'My Complaints', onTap: () {}),
                _buildProfileItem(Icons.notifications_outlined, 'Notifications', onTap: () {}),
                _buildProfileItem(Icons.info_outline, 'About Us', onTap: () {}),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                           color: AppColors.error.withOpacity(0.12),
                           shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout, color: AppColors.error, size: 24),
                      ),
                      title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.error)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
                      onTap: _logout,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
