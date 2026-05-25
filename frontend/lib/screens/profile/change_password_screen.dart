import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdating = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final res = await ApiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Update failed')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPasswordField('Current Password', _currentPasswordController, _obscureCurrent, () {
              setState(() => _obscureCurrent = !_obscureCurrent);
            }),
            const SizedBox(height: 16),
            _buildPasswordField('New Password', _newPasswordController, _obscureNew, () {
              setState(() => _obscureNew = !_obscureNew);
            }),
            const SizedBox(height: 16),
            _buildPasswordField('Confirm New Password', _confirmPasswordController, _obscureConfirm, () {
               setState(() => _obscureConfirm = !_obscureConfirm);
            }),
            const SizedBox(height: 24),
            const Text('Password must contain:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRuleItem('At least 8 characters', _newPasswordController.text.length >= 8),
            _buildRuleItem('One uppercase letter', _newPasswordController.text.contains(RegExp(r'[A-Z]'))),
            _buildRuleItem('One number', _newPasswordController.text.contains(RegExp(r'[0-9]'))),
            _buildRuleItem('One special character', _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isUpdating ? null : _updatePassword,
              child: _isUpdating
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller, bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: (v) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
           icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
           onPressed: toggle,
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: isMet ? AppColors.success : Colors.grey.shade300, size: 16),
          const SizedBox(width: 8),
          Text(rule, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
