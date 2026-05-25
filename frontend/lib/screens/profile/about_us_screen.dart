import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Us', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/logos/logo.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.atm, size: 80, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('CleanATM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'CleanATM is an initiative to keep ATMs clean and well-maintained for a better banking experience.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 48),
            _buildLinkItem('Privacy Policy'),
            _buildLinkItem('Terms & Conditions'),
            _buildLinkItem('Contact Us'),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () {},
    );
  }
}
