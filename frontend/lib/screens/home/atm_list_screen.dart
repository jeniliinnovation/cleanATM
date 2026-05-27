import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../complaints/file_report_screen.dart';
import '../../services/api_service.dart';

class AtmListScreen extends StatefulWidget {
  final String? filterBank;
  final Function(int)? onNavigateToTab;
  const AtmListScreen({super.key, this.filterBank, this.onNavigateToTab});

  @override
  State<AtmListScreen> createState() => _AtmListScreenState();
}

class _AtmListScreenState extends State<AtmListScreen> {
  List<dynamic> _allAtms = [];
  List<dynamic> _filteredAtms = [];
  List<Map<String, dynamic>> _groupedBanks = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  
  String? _activeBankFilter;
  String? _activeCityFilter;
  bool _showNearbyOnly = false;
  bool _showBookmarkedOnly = false;

  Set<String> _bookmarkedAtmIds = {};

  static const double _userLatitude = 28.6300;
  static const double _userLongitude = 77.2200;

  @override
  void initState() {
    super.initState();
    _activeBankFilter = widget.filterBank;
    if (_activeBankFilter != null) {
      _searchController.text = _activeBankFilter!;
    }
    _loadBookmarks().then((_) => _loadAtms());
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _bookmarkedAtmIds = (prefs.getStringList('bookmarked_atms') ?? []).toSet();
      });
    } catch (_) {}
  }

  Future<void> _toggleBookmark(String atmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (_bookmarkedAtmIds.contains(atmId)) {
          _bookmarkedAtmIds.remove(atmId);
        } else {
          _bookmarkedAtmIds.add(atmId);
        }
      });
      await prefs.setStringList('bookmarked_atms', _bookmarkedAtmIds.toList());
    } catch (_) {}
  }

  Future<void> _loadAtms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.listAtms();
      if (result['success'] == true) {
        if (!mounted) return;
        setState(() {
          final data = result['data'];
          if (data != null && data is Map && data['atms'] is List) {
            _allAtms = data['atms'];
          } else {
            _allAtms = [];
          }
          _processBankGroups();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        if (!mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) setState(() => _isLoading = false);
    }
  }

  void _processBankGroups() {
    final Map<String, List<dynamic>> groups = {};
    for (var atm in _allAtms) {
      final String bank = atm['bank_name'] ?? 'Other Bank';
      if (!groups.containsKey(bank)) groups[bank] = [];
      groups[bank]!.add(atm);
    }
    
    _groupedBanks = groups.entries.map((e) => {
      'name': e.key,
      'atms': e.value,
      'count': e.value.length,
      'logo': ApiService.getBankLogo(e.key),
    }).toList();
    
    _groupedBanks.sort((a, b) => b['count'].compareTo(a['count']));
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
          cos(lat1 * p) * cos(lat2 * p) *
          (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredAtms = _allAtms.where((atm) {
        final name = (atm['bank_name'] ?? '').toString().toLowerCase();
        final id = (atm['atm_id'] ?? '').toString().toLowerCase();
        final city = (atm['city'] ?? '').toString().toLowerCase();
        final address = (atm['address'] ?? '').toString().toLowerCase();
        
        final matchesQuery = query.isEmpty ||
            name.contains(query) ||
            id.contains(query) ||
            city.contains(query) ||
            address.contains(query);

        if (!matchesQuery) return false;

        if (_activeBankFilter != null && _activeBankFilter != 'All Banks') {
          if (!name.contains(_activeBankFilter!.toLowerCase())) return false;
        }

        if (_activeCityFilter != null && _activeCityFilter != 'All Cities') {
          if (city != _activeCityFilter!.toLowerCase()) return false;
        }

        if (_showBookmarkedOnly && !_bookmarkedAtmIds.contains(atm['atm_id'].toString())) return false;

        if (_showNearbyOnly) {
          final double? atmLat = atm['latitude'] != null ? double.tryParse(atm['latitude'].toString()) : null;
          final double? atmLng = atm['longitude'] != null ? double.tryParse(atm['longitude'].toString()) : null;
          if (atmLat != null && atmLng != null) {
            final distance = _calculateDistance(_userLatitude, _userLongitude, atmLat, atmLng);
            if (distance > 30.0) return false;
          } else {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Advanced Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.8)),
                   IconButton(
                     icon: Container(
                       padding: const EdgeInsets.all(6),
                       decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                       child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                     ),
                     onPressed: () => Navigator.pop(ctx)
                   ),
                ],
              ),
              const SizedBox(height: 30),
              _buildFilterSwitch('Saved & Bookmarked', Icons.bookmark_rounded, const Color(0xFF10B981), _showBookmarkedOnly, (v) {
                setModalState(() => _showBookmarkedOnly = v);
                setState(() { _showBookmarkedOnly = v; _applyFilters(); });
              }),
              const SizedBox(height: 12),
              _buildFilterSwitch('Nearby Terminals', Icons.my_location_rounded, const Color(0xFF3B82F6), _showNearbyOnly, (v) {
                setModalState(() => _showNearbyOnly = v);
                setState(() { _showNearbyOnly = v; _applyFilters(); });
              }),
              const SizedBox(height: 32),
              const Text('Target City', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
              _buildDropdown(['All Cities', 'Delhi', 'Mumbai', 'Bangalore', 'Kolkata', 'Chennai', 'Hyderabad'], _activeCityFilter ?? 'All Cities', (v) {
                setModalState(() => _activeCityFilter = v == 'All Cities' ? null : v);
                setState(() { _activeCityFilter = v == 'All Cities' ? null : v; _applyFilters(); });
              }),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply Selection', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSwitch(String title, IconData icon, Color color, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: SwitchListTile.adaptive(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
        value: value,
        activeColor: const Color(0xFF10B981),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF10B981)),
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 15),
          items: items.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showingAtms = _activeBankFilter != null;

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
          onPressed: () {
            if (showingAtms) {
              setState(() { _activeBankFilter = null; _applyFilters(); });
            } else {
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(0);
              } else {
                Navigator.pop(context);
              }
            }
          },
        ),
        title: Text(
          showingAtms ? 'Select Terminal' : 'Bank Bench', 
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.8)
        ),
        actions: const [
          SizedBox(width: 56), // To balance the leading back button
        ],
      ),
      body: Stack(
        children: [
          // Subtle background gradient
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
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
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (!showingAtms) SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 25, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Partner Banks',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access terminals across our 20+ primary partners in your city.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 25, 24, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                            border: Border.all(color: Colors.grey.shade50),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => _applyFilters(),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search bank or location...',
                              hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14, fontWeight: FontWeight.w600),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF10B981), size: 22),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: _showFilterBottomSheet,
                        child: Container(
                          height: 56, width: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                            border: Border.all(color: Colors.grey.shade50),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))))
              else if (showingAtms)
                _buildAtmListView()
              else
                _buildBankBenchView(),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankBenchView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final bank = _groupedBanks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
                border: Border.all(color: Colors.grey.shade50),
              ),
              child: ListTile(
                onTap: () => setState(() { _activeBankFilter = bank['name']; _applyFilters(); }),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: Container(
                  width: 56, height: 56,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
                  child: Center(child: _brandLogo(bank['logo'], size: 32)),
                ),
                title: Text(bank['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                subtitle: Text('${bank['count']} Terminals Nearby', style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w700)),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF10B981)),
                ),
              ),
            );
          },
          childCount: _groupedBanks.length,
        ),
      ),
    );
  }

  Widget _buildAtmListView() {
    final list = _filteredAtms;
    if (list.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade100),
              const SizedBox(height: 20),
              Text('No terminals found in this area', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPrimeAtmCard(list[index]),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildPrimeAtmCard(Map<String, dynamic> atm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: InkWell(
        onTap: () => _showAtmDetails(atm),
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
                      'ID: #${atm['atm_id'].toString().toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                atm['bank_name'] ?? 'ATM Terminal',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Color(0xFF1E293B), letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      atm['address'] ?? 'No address provided',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600),
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
                  Text(
                    atm['city'] ?? 'Location Available',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  GestureDetector(
                    onTap: () => _toggleBookmark(atm['atm_id'].toString()),
                    child: Icon(
                      _bookmarkedAtmIds.contains(atm['atm_id'].toString()) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 24, color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showAtmDetails(Map<String, dynamic> atm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 30, offset: Offset(0, -10))],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 30),
              
              Row(
                children: [
                  Container(
                    width: 76, height: 76,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.06), borderRadius: BorderRadius.circular(24)),
                    child: Center(child: _brandLogo(ApiService.getBankLogo(atm['bank_name'] ?? ''), size: 45)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${atm['bank_name'] ?? 'ATM'} Terminal', 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.8)
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(atm['city'] ?? 'Location Available', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(100)),
                          child: const Text('STATUS: ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 35),
              _buildModernDetailItem(Icons.map_rounded, 'Full Address', atm['address'] ?? 'Detailed address information...'),
              _buildModernDetailItem(Icons.account_tree_rounded, 'Branch Office', '${atm['bank_name'] ?? 'Local'} Main Branch'),
              _buildModernDetailItem(Icons.schedule_rounded, 'Operating Hours', '24 Hours / 7 Days Access'),
              
              const SizedBox(height: 35),
              
              Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FileReportScreen(initialAtmId: atm['atm_id'].toString())));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  child: const Text('File a Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(icon, size: 20, color: const Color(0xFF10B981)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w700, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandLogo(String path, {double size = 50}) {
    if (path.isEmpty) return Icon(Icons.business_rounded, size: size * 0.7, color: const Color(0xFF10B981));
    if (path.contains('logos/')) {
      return Image.asset('assets/' + path, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.business_rounded, size: size * 0.7, color: const Color(0xFF10B981)));
    }
    return Image.network(path, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.business_rounded, size: size * 0.7, color: const Color(0xFF10B981)));
  }
}
