import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
      backgroundColor: const Color(0xFFF9FFF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Incident Lab',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.8)
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
                color: const Color(0xFF10B981).withOpacity(0.03),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your Records',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0),
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : RefreshIndicator(
                      onRefresh: _fetchComplaints,
                      color: const Color(0xFF10B981),
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
                color: isSelected ? const Color(0xFF10B981) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [
                  BoxShadow(color: const Color(0xFF10B981).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))
                ] : [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
                border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFF1F5F9)),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
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
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '#CMP${c['complaint_id'].toString().substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                  ),
                  _buildPrimeStatusBadge(status),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                bankName,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B), letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF10B981)),
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
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: Color(0xFF3B82F6)),
                          SizedBox(width: 4),
                          Text('CAN EDIT', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    )
                  else
                    const SizedBox(),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800),
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
            gradient: LinearGradient(colors: [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF10B981).withOpacity(0.05)]),
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
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF10B981), size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Modify Record', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                   Text('Swipe to open editor', style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 11)),
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
        color = const Color(0xFF10B981);
        text = 'RESOLVED';
        bgColor = const Color(0xFF10B981).withOpacity(0.12);
        break;
      case 'in_progress':
        color = const Color(0xFF3B82F6);
        text = 'IN PROGRESS';
        bgColor = const Color(0xFF3B82F6).withOpacity(0.12);
        break;
      case 'rejected':
        color = const Color(0xFFEF4444);
        text = 'REJECTED';
        bgColor = const Color(0xFFEF4444).withOpacity(0.12);
        break;
      default:
        color = const Color(0xFFF59E0B);
        text = 'PENDING';
        bgColor = const Color(0xFFF59E0B).withOpacity(0.12);
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
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(Icons.assignment_rounded, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 25),
          const Text(
            'Clear as Day', 
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 20)
          ),
          const SizedBox(height: 8),
          Text(
            'No active incidents found in this filter.', 
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15)
          ),
        ],
      ),
    );
  }
}
