import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'camera_screen.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Map<String, dynamic> _complaint;
  bool _isUpdating = false;

  bool _canEdit() {
    if (_complaint['status'] != 'pending') return false;
    if (_complaint['createdAt'] == null) return false;
    try {
      final created = DateTime.parse(_complaint['createdAt']);
      final now = DateTime.now().toUtc();
      // Calculate difference in hours
      final diff = now.difference(created).inHours;
      return diff < 2;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
  }

  Future<void> _showEditDialog() async {
    final descCtrl = TextEditingController(text: _complaint['description']);
    Uint8List? selectedImage;
    String? imageName;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Update your description...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Update Photo (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final choice = await showModalBottomSheet<String>(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(ctx, 'camera')),
                          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(ctx, 'gallery')),
                        ],
                      ),
                    );
                    if (choice == null) return;
                    XFile? photo;
                    if (choice == 'camera') {
                      photo = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen()));
                    } else {
                      photo = await ImagePicker().pickImage(source: ImageSource.gallery);
                    }
                    if (photo != null) {
                      final bytes = await photo.readAsBytes();
                      setModalState(() {
                        selectedImage = bytes;
                        imageName = photo!.name;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2, style: BorderStyle.solid),
                    ),
                    child: selectedImage != null 
                      ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(selectedImage!, fit: BoxFit.cover))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_rounded, color: Colors.blue.shade400, size: 32),
                          const SizedBox(height: 8),
                          const Text('Replace current photo', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ]),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isUpdating ? null : () async {
                      setModalState(() => _isUpdating = true);
                      final res = await ApiService.updateComplaint(
                        complaintId: _complaint['complaint_id'].toString(),
                        description: descCtrl.text,
                        imageBytes: selectedImage,
                        imageName: imageName,
                      );
                      if (res['success'] == true) {
                        setState(() => _complaint = res['data']);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Report updated!'), backgroundColor: Colors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: ${res['message']}'), backgroundColor: Colors.red));
                      }
                      setModalState(() => _isUpdating = false);
                    },
                    child: _isUpdating 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String status = _complaint['status'] ?? 'pending';
    final Color statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _canEdit() ? FloatingActionButton.extended(
        onPressed: _showEditDialog,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D47A1),
        elevation: 4,
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text('Edit Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ) : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView(
                    children: [
                      _buildHeaderImage(_complaint['photo_url']),
                      _buildHeaderImage(null, placeholderIndex: 1),
                      _buildHeaderImage(null, placeholderIndex: 2),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          )),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 220, left: 20, right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.atm_rounded, color: Color(0xFF0D47A1), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _complaint['bank_name'] ?? 'Bank Managed ATM',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _complaint['location'] ?? 'ATM Location Address',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50, left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 140, left: 24, right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Complaint\nDetails',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                          ),
                          child: _brandLogo(ApiService.getBankLogo(_complaint['bank_name'] ?? ''), size: 36),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF0D47A1),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 80)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusChip(status: status, color: statusColor),
                      Text(
                        compaint_id_short(_complaint['complaint_id']?.toString() ?? ''),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Text(
                    _complaint['description'] ?? 'No description provided.',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  _DetailRow(icon: Icons.atm_rounded, label: 'ATM ID', value: _complaint['atm_id']?.toString() ?? 'N/A'),
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.category_rounded, label: 'Issue Type', value: _complaint['complaint_type']?.toString().toUpperCase() ?? 'OTHER'),
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.calendar_today_rounded, label: 'Reported on', value: _formatDate(_complaint['createdAt'])),
                  
                  const SizedBox(height: 40),
                  const Text('Report Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(
                              index == 0 && _complaint['photo_url'] != null
                                  ? 'http://localhost:5000/${_complaint['photo_url']}'
                                  : [
                                      'https://images.unsplash.com/photo-1541339907198-e08756edd811?w=400',
                                      'https://images.unsplash.com/photo-1526628953301-3e589a6a8b74?w=400',
                                      'https://images.unsplash.com/photo-1501167786227-4cba60f6d58f?w=400',
                                    ][index],
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 24),
                  _TimelineItem(
                    title: 'Complaint Submitted',
                    subtitle: 'Your report was successfully logged in the system.',
                    time: _formatDate(_complaint['createdAt']),
                    isLast: status == 'pending',
                    isPast: true,
                    activeColor: Colors.blue,
                  ),
                  if (status != 'pending')
                    _TimelineItem(
                      title: 'Investigation In Progress',
                      subtitle: 'A technician has been assigned to check the ATM.',
                      time: 'Updating...',
                      isLast: status == 'in_progress',
                      isPast: status == 'in_progress' || status == 'resolved',
                      activeColor: Colors.orange,
                    ),
                  if (status == 'resolved')
                    _TimelineItem(
                      title: 'Issue Resolved',
                      subtitle: 'Hygiene standards have been restored at this location.',
                      time: _formatDate(_complaint['resolved_at']),
                      isLast: true,
                      isPast: true,
                      activeColor: Colors.green,
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String compaint_id_short(String id) {
    if (id.length > 8) return 'ID: #${id.substring(0, 8)}...';
    return 'ID: #$id';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    return date.toString().split('T')[0];
  }

  Widget _buildHeaderImage(String? photoUrl, {int placeholderIndex = 0}) {
    if (photoUrl != null) {
      return Image.network(
        'http://localhost:5000/$photoUrl',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(placeholderIndex),
      );
    }
    return _buildPlaceholder(placeholderIndex);
  }

  Widget _buildPlaceholder(int index) {
    final List<String> placeholders = [
      'https://images.unsplash.com/photo-1541339907198-e08756edd811?w=800&q=80',
      'https://images.unsplash.com/photo-1526628953301-3e589a6a8b74?w=800&q=80',
      'https://images.unsplash.com/photo-1501167786227-4cba60f6d58f?w=800&q=80',
    ];
    return Image.network(
      placeholders[index % placeholders.length],
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator()));
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _brandLogo(String path, {double size = 24}) {
    if (path.contains('logos/')) {
      return Image.asset(
        'assets/' + path,
        height: size,
        width: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: size * 0.8, color: const Color(0xFF0D47A1)),
      );
    }
    return Image.network(
      path,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: size * 0.8, color: const Color(0xFF0D47A1)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isLast;
  final bool isPast;
  final Color activeColor;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isLast,
    required this.isPast,
    this.activeColor = const Color(0xFF0D47A1),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isPast ? activeColor : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  if (isPast) BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: isPast ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isPast ? activeColor.withOpacity(0.6) : Colors.grey.shade200,
                      isPast ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPast ? const Color(0xFF1E293B) : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: (isPast ? activeColor : Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(time, style: TextStyle(color: isPast ? activeColor : Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
