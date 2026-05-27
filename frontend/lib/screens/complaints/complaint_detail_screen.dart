import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_report_screen.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
      }
    });
  }

  void _calculateRemainingTime() {
    final dateRaw = widget.complaint['createdAt'] ?? widget.complaint['created_at'];
    if (dateRaw != null) {
      try {
        final createdAt = DateTime.parse(dateRaw.toString());
        final now = DateTime.now();
        final difference = now.difference(createdAt);
        final limit = const Duration(hours: 2);

        if (difference >= limit) {
          _isClosed = true;
          _remainingTime = Duration.zero;
          _timer?.cancel();
        } else {
          _isClosed = false;
          _remainingTime = limit - difference;
        }
      } catch (_) {
        _isClosed = true;
      }
    } else {
      _isClosed = true;
    }
  }

  String _formatCountdown() {
    if (_isClosed) return "Window Closed";
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes % 60;
    return "Closes in ${hours}h ${minutes}m";
  }

  /// Build the full image URL from a stored path like "uploads/complaints/xxx.png"
  String _buildImageUrl(String path) {
    // Remove leading slash if any
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return 'http://localhost:5000/$cleanPath';
  }

  /// Collect all photo URLs from both photo_url and photo_urls fields
  List<String> _getAllPhotoUrls() {
    final List<String> urls = [];
    final photoUrls = widget.complaint['photo_urls'];
    if (photoUrls != null) {
      if (photoUrls is List) {
        for (var url in photoUrls) {
          if (url != null && url.toString().isNotEmpty) {
            urls.add(url.toString());
          }
        }
      } else if (photoUrls is String && photoUrls.isNotEmpty) {
        urls.add(photoUrls);
      }
    }
    if (urls.isEmpty) {
      final singleUrl = widget.complaint['photo_url'];
      if (singleUrl != null && singleUrl.toString().isNotEmpty) {
        urls.add(singleUrl.toString());
      }
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final atmData = widget.complaint['ATM'] ?? {};
    final title = atmData['bank_name'] ?? widget.complaint['bank_name'] ?? 'ATM Terminal';
    final id = widget.complaint['complaint_id']?.toString() ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
    
    final dateRaw = widget.complaint['createdAt'] ?? widget.complaint['created_at'];
    String dateStr = '-- --- ----';
    if (dateRaw != null) {
      try {
        final date = DateTime.parse(dateRaw.toString());
        dateStr = DateFormat('dd MMM yyyy').format(date);
      } catch (_) {}
    }

    final photoUrls = _getAllPhotoUrls();

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
          'Incident Insight',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.8)
        ),
      ),
      body: Stack(
        children: [
          // Background Decorative Blur
          Positioned(
            top: 100,
            right: -60,
            child: Container(
              width: 200, height: 200,
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

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'REF: #$shortId',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5),
                            ),
                          ),
                          _buildPrimeStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E293B), letterSpacing: -0.8),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              atmData['address'] ?? 'Terminal Location',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w700),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(dateStr, style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          if (!_isClosed) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text(_formatCountdown(), style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),
                _buildPrimeSectionHeader('Operational Intelligence'),
                const SizedBox(height: 16),
                _buildModernDetailItem(Icons.description_rounded, 'Incident Description', widget.complaint['description'] ?? 'No details provided.', color: const Color(0xFF3B82F6)),
                _buildModernDetailItem(Icons.category_rounded, 'Issue Category', (widget.complaint['complaint_type'] ?? 'General').toString().replaceAll('_', ' ').toUpperCase(), color: const Color(0xFFF59E0B)),
                
                const SizedBox(height: 35),
                _buildPrimeSectionHeader('Visual Evidence'),
                const SizedBox(height: 16),
                
                if (photoUrls.isNotEmpty) 
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: photoUrls.length,
                      itemBuilder: (context, index) {
                        final imageUrl = _buildImageUrl(photoUrls[index]);
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(context, imageUrl),
                          child: Container(
                            width: 180,
                            margin: EdgeInsets.only(right: index < photoUrls.length - 1 ? 16 : 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Container(color: const Color(0xFFF8FAFC), child: const Center(child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2))),
                                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFF8FAFC), child: Icon(Icons.broken_image_rounded, color: Colors.grey.shade200, size: 40)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  _buildNoEvidenceState(),

                const SizedBox(height: 35),
                _buildPrimeSectionHeader('Resolution Track'),
                const SizedBox(height: 20),
                _buildPrimeTimelineItem(
                  'Incident Lodged',
                  'System successfully registered the telemetry alert.',
                  isCompleted: true,
                  isFirst: true,
                  icon: Icons.radio_button_checked_rounded,
                  color: const Color(0xFF10B981),
                ),
                _buildPrimeTimelineItem(
                  _isClosed ? 'Session Closed' : 'Tracking Active',
                  _isClosed ? 'The 2h resolution window has expired.' : 'Real-time monitoring is currently active.',
                  isCompleted: _isClosed,
                  isLast: true,
                  icon: _isClosed ? Icons.lock_rounded : Icons.sensors_rounded,
                  color: _isClosed ? const Color(0xFF64748B) : const Color(0xFF3B82F6),
                ),

                const SizedBox(height: 48),

                if (!_isClosed)
                  Container(
                    width: double.infinity,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditReportScreen(complaint: widget.complaint)));
                        if (updated == true) Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                      child: const Text('Modify Record', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock_rounded, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Edit Window Expired', style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w900, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('Modifications are disabled after 2 hours for data integrity.', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimeSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B), letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildPrimeStatusBadge() {
    final status = (widget.complaint['status'] ?? 'pending').toString().toLowerCase();
    
    Color color;
    String text;
    Color bgColor;

    switch (status) {
      case 'resolved':
      case 'completed':
        color = const Color(0xFF10B981);
        text = 'RESOLVED';
        bgColor = const Color(0xFFDCFCE7);
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
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailItem(IconData icon, String label, String value, {required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEvidenceState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9), width: 2)),
      child: Column(
        children: [
          Icon(Icons.photo_library_rounded, size: 32, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No Visual Data', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPrimeTimelineItem(String title, String subtitle, {bool isCompleted = false, bool isFirst = false, bool isLast = false, required IconData icon, required Color color}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 2, height: 20, color: isFirst ? Colors.transparent : const Color(0xFFF1F5F9)),
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isCompleted ? color.withOpacity(0.1) : Colors.transparent, shape: BoxShape.circle), child: Icon(icon, size: 16, color: isCompleted ? color : Colors.grey.shade200)),
              Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : const Color(0xFFF1F5F9))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Text(title, style: TextStyle(color: isCompleted ? const Color(0xFF1E293B) : Colors.grey.shade400, fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: isCompleted ? const Color(0xFF64748B) : Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: Colors.grey.shade900,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 60)),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10, right: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
