import 'package:flutter/material.dart';
import 'atm_list_screen.dart';
import 'complaints_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  String? _pendingBankFilter;
  bool _pendingAutoOpenReport = false;

  void navigateTo(int index, {String? bankFilter, bool openReport = false}) {
    setState(() {
      currentIndex = index;
      _pendingBankFilter = bankFilter;
      _pendingAutoOpenReport = openReport;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;
    switch (currentIndex) {
      case 1:
        activeScreen = AtmListScreen(filterBank: _pendingBankFilter);
        break;
      case 2:
        activeScreen = ComplaintsScreen(autoOpenAdd: _pendingAutoOpenReport);
        break;
      case 3:
        activeScreen = const ProfileScreen();
        break;
      default:
        activeScreen = const _DashboardView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: KeyedSubtree(
          key: ValueKey(currentIndex.toString() + (_pendingBankFilter ?? '') + _pendingAutoOpenReport.toString()),
          child: activeScreen,
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIcon(index: 0, activeIndex: currentIndex, icon: Icons.grid_view_rounded, label: 'Home', onTap: () => navigateTo(0)),
            _NavIcon(index: 1, activeIndex: currentIndex, icon: Icons.location_on_outlined, label: 'ATMs', onTap: () => navigateTo(1)),
            _NavIcon(index: 2, activeIndex: currentIndex, icon: Icons.add_circle_outline_rounded, label: 'Report', onTap: () => navigateTo(2)),
            _NavIcon(index: 3, activeIndex: currentIndex, icon: Icons.person_outline_rounded, label: 'Account', onTap: () => navigateTo(3)),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final int index;
  final int activeIndex;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavIcon({required this.index, required this.activeIndex, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    bool active = index == activeIndex;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(color: active ? const Color(0xFFE3F2FD) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: active ? const Color(0xFF0D47A1) : Colors.grey, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? const Color(0xFF0D47A1) : Colors.grey, fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  List<dynamic> _atms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService.listAtms();
      if (mounted) {
        final List<dynamic> allAtms = res['data']?['atms'] ?? [];
        
        // Group by Bank Name ONLY and calculate counts
        final Map<String, int> bankCounts = {};
        final List<dynamic> uniqueBanks = [];
        final Set<String> seenBanks = {};
        
        for (var atm in allAtms) {
          final String bank = atm['bank_name'] ?? 'Bank';
          bankCounts[bank] = (bankCounts[bank] ?? 0) + 1;
          
          if (!seenBanks.contains(bank)) {
            seenBanks.add(bank);
            uniqueBanks.add(atm);
          }
        }

        setState(() {
          // Attach counts to the bank data for UI
          _atms = uniqueBanks.map((b) {
             b['_count'] = bankCounts[b['bank_name']];
             return b;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 40),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CleanGuard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('ATM Monitor', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _DashboardHero(onTap: () => context.findAncestorStateOfType<_HomeScreenState>()?.navigateTo(2, openReport: true)),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Partner Banks', onTap: () => context.findAncestorStateOfType<_HomeScreenState>()?.navigateTo(1)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _atms.length,
                itemBuilder: (context, index) {
                  final bankData = _atms[index];
                  final String name = bankData['bank_name'] ?? 'Bank';
                  final int count = bankData['_count'] ?? 0;
                  
                  return _LiveAtmCard(
                    bank: name,
                    location: '$count Locations',
                    status: 'clean',
                    onTap: () => context.findAncestorStateOfType<_HomeScreenState>()?.navigateTo(1, bankFilter: name),
                  );
                },
              ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Operations'),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _OpButton(
                    icon: Icons.camera_alt_rounded,
                    title: 'Snap & Report',
                    subtitle: 'Quick issue logging',
                    color: const Color(0xFF673AB7),
                    onTap: () => context.findAncestorStateOfType<_HomeScreenState>()?.navigateTo(2, openReport: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OpButton(
                    icon: Icons.history_rounded,
                    title: 'My History',
                    subtitle: 'Track your reports',
                    color: const Color(0xFF009688),
                    onTap: () => context.findAncestorStateOfType<_HomeScreenState>()?.navigateTo(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final VoidCallback onTap;
  const _DashboardHero({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Smart Monitoring', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Text('1.2k ATMs Protected', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Keep your city\'s banking clean and safe for everyone. Join our 5k+ active guardians.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('New Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionHeader({required this.title, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          if (onTap != null) GestureDetector(onTap: onTap, child: const Text('View All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _LiveAtmCard extends StatelessWidget {
  final String bank;
  final String location;
  final String status;
  final VoidCallback onTap;
  const _LiveAtmCard({required this.bank, required this.location, required this.status, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(32), 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9))
        ),
        child: Column(
          children: [
            Container(
              height: 48,
              width: 48,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _brandLogo(ApiService.getBankLogo(bank), size: 28),
            ),
            const Spacer(),
            Text(bank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(location, style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _brandLogo(String path, {double size = 20}) {
    if (path.contains('logos/')) {
      return Image.asset(
        'assets/' + path,
        height: size,
        width: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: size, color: const Color(0xFF0D47A1)),
      );
    }
    return Image.network(
      path,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: size, color: const Color(0xFF0D47A1)),
    );
  }
}

class _OpButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _OpButton({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(28), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
