import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import 'complaint_detail_screen.dart';

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
    
    final normalizedFilter = _activeFilter.toLowerCase().replaceAll(' ', '_');
    return _allComplaints.where((c) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      if (normalizedFilter == 'in_progress' && status == 'in_progress') return true;
      if (normalizedFilter == 'pending' && status == 'pending') return true;
      if (normalizedFilter == 'resolved' && (status == 'resolved' || status == 'completed')) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredComplaints;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      const Text(
                        'My Complaints',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _fetchComplaints,
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                
                // Filters
                _buildFilterChips(),
                
                // List
                Expanded(
                  child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchComplaints,
                        color: AppColors.primary,
                        child: filtered.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
                              children: [
                                Column(
                                  children: [
                                    Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.2)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reports match the filter',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontWeight: FontWeight.w600, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                return _buildGlassComplaintCard(c);
                              },
                            ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'In Progress', 'Pending', 'Resolved'];
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _activeFilter == filter;
          return GestureDetector(
            onTap: () => _setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(100),
                boxShadow: isSelected 
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))] 
                  : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassComplaintCard(Map<String, dynamic> c) {
    final atmData = c['ATM'] ?? {};
    final bName = atmData['bank_name'] ?? c['bank_name'] ?? 'ATM ${c['atm_id']}';
    final id = '#CMP${c['complaint_id']}';
    final date = c['created_at'] != null ? c['created_at'].toString().split('T').first : 'Unknown Date';
    final status = c['status']?.toString() ?? 'pending';
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: c)));
              },
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            id,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primary, letterSpacing: 0.5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            status.replaceFirst('_', ' ').toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      bName,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower == 'resolved' || lower == 'completed') return AppColors.success;
    if (lower == 'in_progress') return AppColors.warning;
    return Colors.deepOrangeAccent;
  }
}

