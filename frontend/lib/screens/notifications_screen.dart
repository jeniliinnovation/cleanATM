import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Complaint Resolved',
        'subtitle': 'Your complaint regarding SBI ATM at Marine Drive has been resolved.',
        'time': '2h ago',
        'icon': Icons.check_circle_rounded,
        'color': Colors.green,
      },
      {
        'title': 'New ATM Alert',
        'subtitle': 'A new HDFC ATM has been added near Gateway of India.',
        'time': '5h ago',
        'icon': Icons.location_on_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Security Update',
        'subtitle': 'Please update your password for better security features.',
        'time': '1d ago',
        'icon': Icons.security_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Weekly Report',
        'subtitle': 'You helped maintain 12 ATMs this week! Thank you for your contribution.',
        'time': '2d ago',
        'icon': Icons.stars_rounded,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text('Activity Center', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5)),
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
                    Positioned(right: -30, top: -20, child: Icon(Icons.notifications_active_rounded, size: 150, color: Colors.white.withOpacity(0.08))),
                    Positioned(left: 20, bottom: 60, child: Icon(Icons.flash_on_rounded, size: 40, color: Colors.white.withOpacity(0.1))),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = notifications[index];
                final color = item['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey.shade50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                            child: Icon(item['icon'] as IconData, color: color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                    Text(item['time'] as String, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(item['subtitle'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: notifications.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}
