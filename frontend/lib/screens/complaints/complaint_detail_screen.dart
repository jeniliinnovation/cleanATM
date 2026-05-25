import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Map<String, dynamic> complaint;
  
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final atmData = complaint['ATM'] ?? {};
    final title = atmData['bank_name'] ?? complaint['bank_name'] ?? 'ATM ${complaint['atm_id']}';
    final id = '#CMP${complaint['complaint_id']}';
    final date = complaint['created_at'] != null ? complaint['created_at'].toString().split('T').first : 'Unknown Date';
    final status = (complaint['status'] ?? 'pending').toString().toLowerCase();

    Color statusColor = Colors.orange;
    if (status == 'in_progress') statusColor = AppColors.warning;
    if (status == 'resolved' || status == 'completed') statusColor = AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complaint Details', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              complaint['description'] ?? 'No description provided.',
              style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (complaint['photo_url'] != null) ...[
               Container(
                 height: 150,
                 decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(12),
                   image: DecorationImage(
                     image: NetworkImage('http://localhost:5000/${complaint['photo_url']}'),
                     fit: BoxFit.cover,
                   ),
                 ),
               ),
            ] else 
              const Text('No photos uploaded', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            const Text('Status Updates', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTimelineItem('Reported', date, isCompleted: true, isFirst: true),
            _buildTimelineItem('Under Review', status == 'in_progress' || status == 'resolved' ? 'Updating status...' : 'Waiting for review', isCompleted: status == 'in_progress' || status == 'resolved'),
            _buildTimelineItem('Resolved', status == 'resolved' ? 'Resolved on ${complaint['resolved_at'] ?? date}' : 'Issue will be resolved soon.', isCompleted: status == 'resolved', isLast: true),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Edit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, {bool isCompleted = false, bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success.withOpacity(0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? AppColors.success : Colors.grey.shade300,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.success.withOpacity(0.5) : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
