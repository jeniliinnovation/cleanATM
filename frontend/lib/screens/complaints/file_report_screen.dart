import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import 'custom_camera_screen.dart';

class FileReportScreen extends StatefulWidget {
  final String? initialAtmId;
  const FileReportScreen({super.key, this.initialAtmId});

  @override
  State<FileReportScreen> createState() => _FileReportScreenState();
}

class _FileReportScreenState extends State<FileReportScreen> {
  final _descController = TextEditingController();
  String _complaintType = 'atm_dirty';
  bool _isLoading = false;
  bool _isFetchingAtms = true;
  
  // ATM Data
  List<dynamic> _atms = [];
  String? _selectedAtmId;

  // Multiple image storage
  final List<XFile> _pickedFiles = [];
  final List<Uint8List> _imagesBytes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedAtmId = widget.initialAtmId;
    _fetchAtms();
  }

  Future<void> _fetchAtms() async {
    try {
      final res = await ApiService.listAtms();
      if (res['success'] == true) {
        setState(() {
          final rawAtms = res['data']?['atms'] ?? [];
          // Filter out ATMs with 'Closed' or 'Maintenance' status
          _atms = rawAtms.where((atm) {
            final status = atm['status']?.toString().toLowerCase();
            return status != 'closed' && status != 'maintenance';
          }).toList();
          
          if (_selectedAtmId != null) {
             final exists = _atms.any((a) => a['atm_id'].toString() == _selectedAtmId);
             if (!exists) _selectedAtmId = null; 
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching atms: $e');
    } finally {
      if (mounted) setState(() => _isFetchingAtms = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedAtmId == null || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an ATM and fill description'),
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
        atmId: _selectedAtmId!,
        complaintType: _complaintType,
        description: _descController.text.trim(),
        imagesBytes: _imagesBytes,
        imagesNames: _pickedFiles.map((f) => f.name).toList(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text('Upload Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _buildSourceBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      // Use Custom Camera Screen (CameraX)
                      final XFile? photo = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
                      );
                      if (photo != null) {
                        final bytes = await photo.readAsBytes();
                        setState(() {
                          _pickedFiles.add(photo);
                          _imagesBytes.add(bytes);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSourceBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> selectedImages = await _picker.pickMultiImage(imageQuality: 70);
        if (selectedImages.isNotEmpty) {
          for (var file in selectedImages) {
            final bytes = await file.readAsBytes();
            setState(() {
              _pickedFiles.add(file);
              _imagesBytes.add(bytes);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
                    _buildSectionHeader('ATM Terminal Selection'),
                    const SizedBox(height: 12),
                    _buildAtmDropdown(),
                    
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
                    _buildSectionHeader('Evidence (Up to 5 images)'),
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

  Widget _buildAtmDropdown() {
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
            child: _isFetchingAtms 
              ? const SizedBox(height: 50, child: Center(child: LinearProgressIndicator()))
              : DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAtmId,
                    hint: const Text('Select ATM Terminal', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: Icon(Icons.atm_rounded, color: AppColors.primary, size: 24),
                    ),
                    icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
                    items: _atms.map((atm) {
                      return DropdownMenuItem<String>(
                        value: atm['atm_id'].toString(),
                        child: Text('${atm['atm_id']} - ${atm['bank_name']}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedAtmId = value);
                    },
                  ),
                ),
          ),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imagesBytes.isNotEmpty)
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 15),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagesBytes.length,
              itemBuilder: (context, index) => Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(_imagesBytes[index], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 5, right: 5,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _pickedFiles.removeAt(index);
                          _imagesBytes.removeAt(index);
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        if (_imagesBytes.length < 5)
          InkWell(
            onTap: _showImageSourceOptions,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: _imagesBytes.isEmpty ? 160 : 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5),
              ),
              child: _imagesBytes.isEmpty 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(height: 12),
                      const Text('Add Evidence Photos', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Up to 5 images for better proof', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontWeight: FontWeight.w500, fontSize: 12)),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text('Add More Photos', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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

