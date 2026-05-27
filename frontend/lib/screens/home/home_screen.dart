import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../profile/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _userName = 'User';
  List<dynamic> _recentComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profileRes = await ApiService.getUserProfile();
      final complRes = await ApiService.getComplaints();

      if (mounted) {
        setState(() {
          if (profileRes['success'] == true) {
            _userName = profileRes['data']?['name'] ?? 'User';
          }
          if (complRes['success'] == true) {
            final allComplaints = (complRes['data'] as List<dynamic>?) ?? [];
            _recentComplaints = allComplaints.take(3).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FFF9),
      body: Stack(
        children: [
          // Background Decorative Blur
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF10B981),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prime Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
                              ),
                              child: const CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person_rounded, color: Color(0xFF10B981), size: 30),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back, 👋',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    _userName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildIconBadge(Icons.notifications_none_rounded, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                            }),
                          ],
                        ),
                        
                        const SizedBox(height: 35),
                        
                        // Status Card
                        _buildStatusCard(),
                        
                        const SizedBox(height: 35),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 20),
                        
                        // Grid Actions
                        Row(
                          children: [
                            _buildActionTile(
                              Icons.add_task_rounded,
                              'File Report',
                              'Fast reporting',
                              const Color(0xFF10B981),
                              () => widget.onNavigateToTab?.call(1), // Go to ATM list or report
                            ),
                            const SizedBox(width: 16),
                            _buildActionTile(
                              Icons.location_on_rounded,
                              'Nearby ATMs',
                              'Locate easily',
                              const Color(0xFF3B82F6),
                              () => widget.onNavigateToTab?.call(1),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reporting History',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                            ),
                            TextButton(
                              onPressed: () => widget.onNavigateToTab?.call(2),
                              child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // History List
                        ..._recentComplaints.isNotEmpty 
                            ? _recentComplaints.map((c) => _buildHistoryCard(c)).toList()
                            : [_buildEmptyHistory()],
                            
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBadge(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 22),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(Icons.clean_hands_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('STATUS: ACTIVE SERV', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const Spacer(),
                const Text(
                  'Make your city\nCleaner today.',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join 5,000+ citizens in our mission.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String desc, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> c) {
    final status = c['status']?.toString() ?? 'Pending';
    final cardColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cardColor.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
            child: Icon(_getStatusIcon(status), color: cardColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['bank_name'] ?? 'ATM Terminal',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Ticket #${c['complaint_id']}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: cardColor.withOpacity(0.08), borderRadius: BorderRadius.circular(100)),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: cardColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.grey.shade100),
            const SizedBox(height: 16),
            Text('No history found', style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    if (status.toLowerCase().contains('resolved')) return Icons.check_circle_rounded;
    if (status.toLowerCase().contains('progress')) return Icons.pending_rounded;
    return Icons.error_rounded;
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('resolved')) return const Color(0xFF10B981);
    if (status.toLowerCase().contains('progress')) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

