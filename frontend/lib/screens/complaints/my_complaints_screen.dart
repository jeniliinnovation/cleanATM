import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import 'complaint_detail_screen.dart';
import 'edit_report_screen.dart';
import 'package:intl/intl.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  bool _isLoading = true;
  List<dynamic> _allComplaints = [];
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final res = await ApiService.getComplaints();
      if (mounted) {
        if (res['success'] == true) {
          setState(() {
            _allComplaints = res['data'] ?? [];
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

  void _setFilter(String filter) {
    setState(() {
      _activeFilter = filter;
    });
  }

  List<dynamic> get _filteredComplaints {
    if (_activeFilter == 'All') return _allComplaints;
    
    final normalizedFilter = _activeFilter.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return _allComplaints.where((c) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      if (normalizedFilter == 'pending' && status == 'pending') return true;
      if (normalizedFilter == 'in_progress' && status == 'in_progress') return true;
      if (normalizedFilter == 'resolved' && (status == 'resolved' || status == 'completed')) return true;
      if (normalizedFilter == 'rejected' && status == 'rejected') return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredComplaints;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Incident Lab',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.8),
        ),
      ),
      body: Stack(
        children: [
          // Background Decorative Blur
          Positioned(
            top: 50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoring',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your Records',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track all your reported incidents and their current status.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              _buildPrimeFilterChips(),
              
              const SizedBox(height: 10),
              
              // List
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchComplaints,
                      color: AppColors.primary,
                      child: filtered.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildPrimeComplaintCard(filtered[index]),
                          ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimeFilterChips() {
    final filters = ['All', 'In Progress', 'Pending', 'Resolved', 'Rejected'];
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _activeFilter == filter;
          return GestureDetector(
            onTap: () => _setFilter(filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))
                ] : [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
                border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrimeComplaintCard(Map<String, dynamic> c) {
    final status = (c['status'] ?? 'pending').toString().toLowerCase();
    final atm = c['ATM'] ?? {};
    final bankName = atm['bank_name'] ?? 'ATM Terminal';
    final location = atm['address'] ?? 'No address provided';
    
    final dateRaw = c['createdAt'] ?? c['created_at'];
    String dateStr = '-- --- ----';
    DateTime? createdAt;
    if (dateRaw != null) {
      try {
        createdAt = DateTime.parse(dateRaw.toString());
        dateStr = DateFormat('dd MMM yyyy').format(createdAt);
      } catch (_) {}
    }

    // Check if within 2-hour edit window
    bool canEdit = false;
    if (status == 'pending' && createdAt != null) {
      final now = DateTime.now();
      final difference = now.difference(createdAt).inHours;
      if (difference < 2) {
        canEdit = true;
      }
    }

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: c))),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '#CMP${c['complaint_id'].toString().substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5),
                    ),
                  ),
                  _buildPrimeStatusBadge(status),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                bankName,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: AppColors.accentBlue),
                          SizedBox(width: 4),
                          Text('CAN EDIT', style: TextStyle(color: AppColors.accentBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    )
                  else
                    const SizedBox(),
                  const Text(
                    '',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (canEdit) {
      return Dismissible(
        key: Key(c['complaint_id'].toString()),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditReportScreen(complaint: c)),
          );
          if (updated == true) _fetchComplaints();
          return false;
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.only(left: 32),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Modify Record', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                   Text('Swipe to open editor', style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        child: card,
      );
    }

    return card;
  }

  Widget _buildPrimeStatusBadge(String status) {
    Color color;
    String text;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'resolved':
      case 'completed':
        color = AppColors.success;
        text = 'RESOLVED';
        bgColor = AppColors.success.withOpacity(0.12);
        break;
      case 'in_progress':
        color = AppColors.accentBlue;
        text = 'IN PROGRESS';
        bgColor = AppColors.accentBlue.withOpacity(0.12);
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'REJECTED';
        bgColor = AppColors.error.withOpacity(0.12);
        break;
      default:
        color = AppColors.warning;
        text = 'PENDING';
        bgColor = AppColors.warning.withOpacity(0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
            child: Icon(Icons.assignment_rounded, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 25),
          const Text(
            'Clear as Day', 
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'No active incidents found in this filter.', 
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
