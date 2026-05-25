import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import 'atm_detail_screen.dart';

class AtmListScreen extends StatefulWidget {
  const AtmListScreen({super.key});

  @override
  State<AtmListScreen> createState() => _AtmListScreenState();
}

class _AtmListScreenState extends State<AtmListScreen> {
  bool _isLoading = true;
  List<dynamic> _allAtms = [];
  List<dynamic> _filteredAtms = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAtms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAtms() async {
    try {
       final result = await ApiService.listAtms();
       if (result['success'] == true) {
          final fetchedAtms = result['data']?['atms'] as List<dynamic>? ?? [];
          if (mounted) {
             setState(() {
                _allAtms = fetchedAtms;
                _filteredAtms = fetchedAtms;
                _isLoading = false;
             });
          }
       } else {
          if (mounted) setState(() => _isLoading = false);
       }
    } catch (_) {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAtms(String query) {
    if (query.isEmpty) {
       setState(() {
         _filteredAtms = _allAtms;
       });
       return;
    }
    
    final q = query.toLowerCase();
    setState(() {
       _filteredAtms = _allAtms.where((atm) {
          final bank = (atm['bank_name'] ?? '').toString().toLowerCase();
          final addr = (atm['address'] ?? '').toString().toLowerCase();
          return bank.contains(q) || addr.contains(q);
       }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ATMs Near You', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterAtms,
                      decoration: const InputDecoration(
                        hintText: 'Search ATM or Location',
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredAtms.isEmpty
                ? const Center(child: Text('No ATMs found', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _filteredAtms.length,
                    itemBuilder: (context, index) {
                      final atm = _filteredAtms[index];
                      // Use bank_name, address, and status
                      return GestureDetector(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => AtmDetailScreen(atm: atm)));
                        },
                        child: _buildAtmItem(
                          atm['bank_name']?.toString() ?? 'Unknown Bank',
                          '${atm['address'] ?? ''}, ${atm['city'] ?? ''}',
                          atm['status']?.toString() ?? 'clean',
                          Icons.account_balance, // generic icon
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtmItem(String title, String subtitle, String status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: status.toLowerCase() == 'clean' ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: status.toLowerCase() == 'clean' ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: status.toLowerCase() == 'clean' ? AppColors.success : AppColors.warning, 
                fontSize: 11, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
