import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AtmListScreen extends StatefulWidget {
  final String? filterBank;
  const AtmListScreen({super.key, this.filterBank});

  @override
  State<AtmListScreen> createState() => _AtmListScreenState();
}

class _AtmListScreenState extends State<AtmListScreen> {
  List<dynamic> _allAtms = [];
  List<dynamic> _filteredAtms = [];
  List<Map<String, dynamic>> _groupedBanks = [];
  bool _isLoading = true;
  
  // Search and Advanced Filters State
  final TextEditingController _searchController = TextEditingController();
  String? _activeBankFilter;
  String? _activeCityFilter;
  bool _showNearbyOnly = false;
  bool _showBookmarkedOnly = false;

  // Bookmarks persistence state
  Set<String> _bookmarkedAtmIds = {};

  // Mock User Coordinates
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
          _allAtms = (result['data'] != null && result['data'] is Map && result['data'].containsKey('atms'))
              ? result['data']['atms']
              : [];
          _processBankGroups();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
    
    // Sort banks by count or name
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

        if (_bookmarkedAtmIds.contains(atm['atm_id'].toString()) == false && _showBookmarkedOnly) return false;

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
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Advanced Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 30, color: Color(0xFFF1F5F9)),
              SwitchListTile.adaptive(
                title: const Text('Saved & Bookmarked Only', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                secondary: const Icon(Icons.star_rounded, color: Colors.amber),
                value: _showBookmarkedOnly,
                onChanged: (v) {
                  setModalState(() => _showBookmarkedOnly = v);
                  setState(() { _showBookmarkedOnly = v; _applyFilters(); });
                },
              ),
              SwitchListTile.adaptive(
                title: const Text('Nearby ATMs Only', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                secondary: const Icon(Icons.my_location_rounded, color: Color(0xFF0D47A1)),
                value: _showNearbyOnly,
                onChanged: (v) {
                  setModalState(() => _showNearbyOnly = v);
                  setState(() { _showNearbyOnly = v; _applyFilters(); });
                },
              ),
              const SizedBox(height: 24),
              const Text('Select City', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              _buildDropdown(['All Cities', 'Delhi', 'Mumbai', 'Bangalore', 'Kolkata', 'Chennai', 'Hyderabad'], _activeCityFilter ?? 'All Cities', (v) {
                setModalState(() => _activeCityFilter = v == 'All Cities' ? null : v);
                setState(() { _activeCityFilter = v == 'All Cities' ? null : v; _applyFilters(); });
              }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAtmDialog,
        backgroundColor: const Color(0xFF5CE1E6),
        foregroundColor: Colors.black87,
        label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 2,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            elevation: 0,
            leading: _activeBankFilter != null ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() { _activeBankFilter = null; _searchController.clear(); _applyFilters(); }),
            ) : null,
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
                    Positioned(right: -30, top: -10, child: Icon(Icons.account_balance_rounded, size: 180, color: Colors.white.withOpacity(0.05))),
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                              child: _activeBankFilter != null 
                                ? _brandLogo(ApiService.getBankLogo(_activeBankFilter!), size: 50)
                                : const Icon(Icons.account_balance_rounded, size: 50, color: Color(0xFF0D47A1)),
                            ),
                            const SizedBox(height: 16),
                            Text(_activeBankFilter ?? 'Partner Banks', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(_activeBankFilter != null ? '${_filteredAtms.length} Active Terminals' : '${_groupedBanks.length} Registered Partners', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Pill
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50, borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => _applyFilters(),
                        decoration: InputDecoration(
                          hintText: _activeBankFilter == null ? 'Search banks...' : 'Search ATMs in $_activeBankFilter...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF0D47A1)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))))
          else if (_activeBankFilter == null)
            _buildBankGridView()
          else
            _buildAtmListView(),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBankGridView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final bank = _groupedBanks[index];
            return GestureDetector(
              onTap: () => setState(() { _activeBankFilter = bank['name']; _searchController.text = bank['name']; _applyFilters(); }),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _brandLogo(bank['logo'], size: 40),
                    const SizedBox(height: 12),
                    Text(bank['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('${bank['count']} ATMs', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
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
    if (_filteredAtms.isEmpty) {
      return SliverFillRemaining(child: Center(child: Text('No terminals found for this bank.')));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildAtmCard(_filteredAtms[index]),
          childCount: _filteredAtms.length,
        ),
      ),
    );
  }

  Widget _buildAtmCard(Map<String, dynamic> atm) {
    final bool isBookmarked = _bookmarkedAtmIds.contains(atm['atm_id'].toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: InkWell(
        onTap: () => _showAtmDetails(atm),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: const Color(0xFFF9C0D3).withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('ATM', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE91E63), fontSize: 12))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(atm['bank_name'] ?? 'Terminal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(
                      '${atm['address'] ?? 'Street Info'}, ${atm['city'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded, color: isBookmarked ? Colors.amber : Colors.grey.shade300),
                onPressed: () => _toggleBookmark(atm['atm_id'].toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAtmDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    String status = 'clean';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register Terminal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                const SizedBox(height: 24),
                _buildField(idCtrl, 'ATM Terminal ID', Icons.qr_code_rounded),
                const SizedBox(height: 16),
                _buildField(nameCtrl, 'Bank Name', Icons.account_balance_rounded),
                const SizedBox(height: 16),
                _buildField(addrCtrl, 'Complete Address', Icons.location_on_rounded),
                const SizedBox(height: 16),
                _buildField(cityCtrl, 'City (e.g. Mumbai)', Icons.location_city_rounded),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () async {
                      if (idCtrl.text.isEmpty) return;
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('auth_token');
                      await http.post(
                        Uri.parse('${ApiService.baseUrl}/admin/atms'),
                        headers: {
                          'Content-Type': 'application/json',
                          if (token != null) 'Authorization': 'Bearer $token',
                        },
                        body: jsonEncode({
                          'atm_id': idCtrl.text,
                          'bank_name': nameCtrl.text,
                          'bank_code': nameCtrl.text.length >= 3 ? nameCtrl.text.substring(0, 3).toUpperCase() : 'BNK',
                          'address': addrCtrl.text,
                          'city': cityCtrl.text,
                          'status': status,
                        }),
                      );
                      Navigator.pop(ctx);
                      _loadAtms();
                    },
                    child: const Text('Add Terminal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: Colors.blue.shade300),
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  void _showAtmDetails(Map<String, dynamic> atm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _brandLogo(ApiService.getBankLogo(atm['bank_name'] ?? ''), size: 40),
                const SizedBox(width: 16),
                Expanded(child: Text(atm['bank_name'] ?? 'ATM Details', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 32),
            _DetailItem(Icons.tag, 'ATM ID', atm['atm_id'] ?? 'N/A'),
            const SizedBox(height: 20),
            _DetailItem(Icons.location_on, 'Location', atm['address'] ?? 'N/A'),
            const SizedBox(height: 20),
            _DetailItem(Icons.map_rounded, 'City', atm['city'] ?? 'N/A'),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _brandLogo(String path, {double size = 50}) {
    if (path.contains('logos/')) {
      return Image.asset('assets/' + path, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.account_balance, size: size * 0.6, color: const Color(0xFF0D47A1)));
    }
    return Image.network(path, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.account_balance, size: size * 0.6, color: const Color(0xFF0D47A1)));
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF0D47A1), size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
        ])),
      ],
    );
  }
}
