import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';

class FileReportScreen extends StatefulWidget {
  const FileReportScreen({super.key});

  @override
  State<FileReportScreen> createState() => _FileReportScreenState();
}

class _FileReportScreenState extends State<FileReportScreen> {
  final _atmIdController = TextEditingController();
  final _descController = TextEditingController();
  String _complaintType = 'atm_dirty';
  bool _isLoading = false;

  @override
  void dispose() {
    _atmIdController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_atmIdController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.submitComplaint(
        atmId: _atmIdController.text.trim(),
        complaintType: _complaintType,
        description: _descController.text.trim(),
      );

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report submitted successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to submit report'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.background.withOpacity(0.8),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'File a Report',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(color: Colors.transparent),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('ATM Terminal ID'),
                    const SizedBox(height: 12),
                    _buildGlassInput(
                      controller: _atmIdController,
                      hint: 'e.g. ATM-7829-X',
                      icon: Icons.atm_rounded,
                    ),
                    
                    const SizedBox(height: 28),
                    _buildSectionHeader('Complaint Type'),
                    const SizedBox(height: 12),
                    _buildGlassDropdown(),
                    
                    const SizedBox(height: 28),
                    _buildSectionHeader('Description'),
                    const SizedBox(height: 12),
                    _buildGlassInput(
                      controller: _descController,
                      hint: 'Tell us what happened...',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: 28),
                    _buildSectionHeader('Evidence'),
                    const SizedBox(height: 12),
                    _buildPhotoUploadSection(),
                    
                    const SizedBox(height: 48),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 22),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _complaintType,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins'),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                items: const [
                  DropdownMenuItem(value: 'atm_dirty', child: Text('ATM is dirty/unhygienic')),
                  DropdownMenuItem(value: 'no_cash', child: Text('No cash available')),
                  DropdownMenuItem(value: 'machine_error', child: Text('Machine not working')),
                  DropdownMenuItem(value: 'vandalism', child: Text('Physical damage/Vandalism')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _complaintType = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5, style: BorderStyle.none), // Dotted border would be better but requires custom painter
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Camera action
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppColors.primary.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 30),
               ),
               const SizedBox(height: 12),
               const Text(
                 'Upload photo evidence',
                 style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
               ),
               Text(
                 'Up to 3 high-quality images',
                 style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontWeight: FontWeight.w500, fontSize: 12),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF22C55E)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
            : const Text(
                'Submit Report',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
              ),
      ),
    );
  }
}

