import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'complaint_detail_screen.dart';
import 'camera_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  final bool autoOpenAdd;
  const ComplaintsScreen({super.key, this.autoOpenAdd = false});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic> _complaints = [];
  List<dynamic> _atms = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.autoOpenAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewComplaintDialog();
      });
    }
  }

  Future<void> _loadInitialData() async {
    await _loadComplaints();
    await _loadAtms();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getComplaints();
      setState(() {
        _complaints = result['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAtms() async {
    try {
      final res = await ApiService.listAtms();
      if (res['success'] == true) {
        setState(() {
          _atms = res['data']?['atms'] ?? [];
        });
      }
    } catch (_) {}
  }

  void _showNewComplaintDialog() {
    final categoryCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    String? selectedAtmId;
    List<Uint8List> selectedImages = [];
    List<String> imageNames = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      image: selectedImages.isNotEmpty
                          ? DecorationImage(image: MemoryImage(selectedImages.first), fit: BoxFit.cover)
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.7)],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_rounded, color: Colors.white, size: 48),
                          SizedBox(height: 12),
                          Text('Submit New Report', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                          Text('Share hygiene observations to help', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(top: 16, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(ctx))),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: TextField(controller: dateCtrl, readOnly: true, decoration: _inputDeco('Assigned Date', Icons.calendar_month_rounded))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedAtmId,
                              isExpanded: true,
                              decoration: _inputDeco('ATM Site', Icons.atm_rounded),
                              items: _atms.map((atm) => DropdownMenuItem(value: atm['atm_id'].toString(), child: Text('${atm['bank_code']} - ${atm['atm_id']}', style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setModalState(() => selectedAtmId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _inputDeco('Incident Category', Icons.category_rounded),
                        items: const [
                          DropdownMenuItem(value: 'dirty', child: Text('🧹 Dirty / Unclean')),
                          DropdownMenuItem(value: 'garbage', child: Text('🗑️ Garbage / Waste')),
                          DropdownMenuItem(value: 'damage', child: Text('🔨 Damage / Broken')),
                          DropdownMenuItem(value: 'ac_issue', child: Text('❄️ AC Issue')),
                          DropdownMenuItem(value: 'no_power', child: Text('⚡ No Power')),
                          DropdownMenuItem(value: 'other', child: Text('📝 Other')),
                        ],
                        onChanged: (v) => setModalState(() => categoryCtrl.text = v ?? ''),
                      ),
                      const SizedBox(height: 20),
                      TextField(controller: descCtrl, maxLines: 5, decoration: _inputDeco('Incident Details', Icons.edit_note_rounded)),
                      const SizedBox(height: 32),
                      const Text('Visual Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == selectedImages.length) {
                              return GestureDetector(
                                onTap: () => _pickImage(setModalState, selectedImages, imageNames),
                                child: Container(
                                  width: 110,
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.1), width: 2)),
                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, color: Colors.blue.shade400), const SizedBox(height: 4), const Text('Add Photo', style: TextStyle(fontSize: 11))]),
                                ),
                              );
                            }
                            return Container(
                              width: 110, margin: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(selectedImages[index], fit: BoxFit.cover, width: 110, height: 120)),
                                  Positioned(top: 6, right: 6, child: GestureDetector(onTap: () => setModalState(() { selectedImages.removeAt(index); imageNames.removeAt(index); }), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)))),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () async {
                              if (selectedAtmId == null || descCtrl.text.isEmpty || categoryCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all fields.'), backgroundColor: Colors.redAccent));
                                return;
                              }
                              final result = await ApiService.submitComplaint(
                                atmId: selectedAtmId!, complaintType: categoryCtrl.text, description: descCtrl.text,
                                imageBytes: selectedImages.isNotEmpty ? selectedImages.first : null,
                                imageName: imageNames.isNotEmpty ? imageNames.first : null,
                              );
                              Navigator.pop(ctx);
                              if (result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Report successfully logged!'), backgroundColor: Colors.green));
                                _loadComplaints();
                              }
                            },
                          child: const Text('Confirm & Log Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(StateSetter setModalState, List<Uint8List> images, List<String> names) async {
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
    if (choice == 'camera') photo = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen()));
    else photo = await ImagePicker().pickImage(source: ImageSource.gallery);
    
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setModalState(() {
        images.add(bytes);
        names.add(photo!.name);
      });
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: Colors.blue.shade300),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  bool _canEdit(Map<String, dynamic> c) {
    if (c['status'] != 'pending') return false;
    if (c['createdAt'] == null) return false;
    try {
      final created = DateTime.parse(c['createdAt']);
      final now = DateTime.now().toUtc();
      final diff = now.difference(created).inHours;
      return diff < 2;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This action will permanently remove this report from the system.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await ApiService.deleteComplaint(c['complaint_id'].toString());
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Report deleted.'), backgroundColor: Colors.redAccent));
        _loadComplaints();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: ${res['message']}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.edit_document, color: Colors.white),
        label: const Text('Log New Issue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: _showNewComplaintDialog,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(right: -20, top: -20, child: Icon(Icons.support_agent_rounded, size: 160, color: Colors.white.withOpacity(0.08))),
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Report Center', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                              child: Text('Tracking ${_complaints.length} active cases', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  _StatusTab('Pending', _getCount('pending'), Colors.orange, _selectedStatus == 'pending'),
                  const SizedBox(width: 12),
                  _StatusTab('Investigating', _getCount('in_progress'), Colors.blue, _selectedStatus == 'in_progress'),
                  const SizedBox(width: 12),
                  _StatusTab('Resolved', _getCount('resolved'), Colors.green, _selectedStatus == 'resolved'),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))))
          else if (_filteredComplaints().isEmpty)
             SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('All clean! No reports found.', style: TextStyle(color: Colors.grey)) ])))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final c = _filteredComplaints()[index];
                    final canEdit = _canEdit(c);
                    
                    return Dismissible(
                      key: Key('complaint_${c['complaint_id']}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          if (canEdit) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailScreen(complaint: c))).then((_) => _loadComplaints());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editing window (2h) has expired.'), backgroundColor: Colors.orange));
                          }
                          return false;
                        } else {
                          // Start to End = Delete
                          _handleDelete(c);
                          return false;
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 32),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(24)),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32), SizedBox(height: 4), Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 32),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(24)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(canEdit ? Icons.edit_rounded : Icons.lock_outline_rounded, color: Colors.white, size: 32), const SizedBox(height: 4), Text(canEdit ? 'Swipe to Edit' : 'Locked', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
                      ),
                      child: _buildComplaintCard(c),
                    );
                  },
                  childCount: _filteredComplaints().length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getCount(String status) => _complaints.where((c) => (c['status'] ?? 'pending').toString().toLowerCase() == status.toLowerCase()).length;

  List<dynamic> _filteredComplaints() {
    if (_selectedStatus == 'all') return _complaints;
    return _complaints.where((c) => (c['status'] ?? 'pending').toString().toLowerCase() == _selectedStatus.toLowerCase()).toList();
  }

  Widget _StatusTab(String label, int count, Color color, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = isActive ? 'all' : (label == 'Pending' ? 'pending' : label == 'Resolved' ? 'resolved' : 'in_progress')),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isActive ? color : Colors.grey.shade100, width: 2),
            boxShadow: [if (isActive) BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Text(count.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isActive ? Colors.white : color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? Colors.white70 : Colors.grey.shade500, letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final uiInfo = _getCategoryUI(c['complaint_type'] ?? '');
    final color = uiInfo['color'] as Color;
    dynamic atm;
    try { atm = _atms.firstWhere((a) => a['atm_id'].toString() == c['atm_id'].toString()); } catch (_) { atm = null; }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailScreen(complaint: c))),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(uiInfo['icon'] as IconData, color: color, size: 26)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(uiInfo['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(atm != null ? '${atm['bank_name']} • ${atm['address']}' : 'ATM ID: ${c['atm_id']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  _StatusPill(c['status']),
                ],
              ),
              const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
              Text(c['description'] ?? '', style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(c['createdAt'] != null ? c['createdAt'].toString().split('T')[0] : 'Just now', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                const Spacer(),
                const Text('View Tracking', style: TextStyle(color: Color(0xFF0D47A1), fontSize: 13, fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0D47A1)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryUI(String type) {
    if (type == 'dirty') return {'name': 'Hygiene Alert', 'icon': Icons.cleaning_services_rounded, 'color': Colors.brown.shade400};
    if (type == 'garbage') return {'name': 'Waste Report', 'icon': Icons.delete_sweep_rounded, 'color': Colors.red.shade400};
    if (type == 'damage') return {'name': 'Damage Alert', 'icon': Icons.home_repair_service_rounded, 'color': Colors.orange.shade400};
    if (type == 'ac_issue') return {'name': 'Climate Issue', 'icon': Icons.ac_unit_rounded, 'color': Colors.blue.shade400};
    return {'name': type.toUpperCase(), 'icon': Icons.report_problem_rounded, 'color': Colors.grey.shade600};
  }

  Widget _StatusPill(String? status) {
    final color = status == 'resolved' ? Colors.green : (status == 'in_progress' ? Colors.blue : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text((status ?? 'pending').toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}
