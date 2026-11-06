import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/storage_service.dart';
import 'screens/dashboard_tab.dart';
import 'screens/items_tab.dart';
import 'screens/challans_tab.dart';
import 'screens/customers_tab.dart';
import 'screens/settings_tab.dart';
import 'screens/create_challan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const RentKeeperApp());
}

class RentKeeperApp extends StatelessWidget {
  const RentKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentKeeper Operational Precision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF001632),
          onPrimary: Colors.white,
          secondary: Color(0xFF006B5F),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFA2F2E4),
          onSecondaryContainer: Color(0xFF00201C),
          surface: Color(0xFFF6F8FA),
          onSurface: Color(0xFF191C1E),
          surfaceContainerLowest: Colors.white,
          surfaceContainer: Color(0xFFEEF1F4),
          surfaceContainerLow: Color(0xFFF3F5F7),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410002),
        ),
        fontFamily: 'Inter',
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final StorageService _storage = StorageService();

  void _refresh() {
    setState(() {});
  }

  void _openCreateChallan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreateChallanScreen(onCreated: _refresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopName = _storage.shop['name'] ?? 'Al-Rehman Rentals';
    final shopCity = _storage.shop['city'] ?? 'LAHORE';
    final todayStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    final tabs = [
      DashboardTab(
        storage: _storage,
        onStateChanged: _refresh,
        onNewBooking: _openCreateChallan,
        onAddItem: () => setState(() => _selectedIndex = 1),
        onAddCustomer: () => setState(() => _selectedIndex = 3),
      ),
      ItemsTab(
        storage: _storage,
        onStateChanged: _refresh,
      ),
      ChallansTab(
        storage: _storage,
        onStateChanged: _refresh,
      ),
      CustomersTab(
        storage: _storage,
        onStateChanged: _refresh,
      ),
      SettingsTab(
        storage: _storage,
        onStateChanged: _refresh,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Sync Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFF001632),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _storage.isOnline
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _storage.isOnline
                        ? 'ONLINE • Synced ${_storage.lastSyncTime}'
                        : 'OFFLINE • Local Storage Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sync Queue: ${_storage.pendingSyncCount}',
                    style: TextStyle(
                      color: _storage.pendingSyncCount > 0
                          ? const Color(0xFFFFB300)
                          : const Color(0xFFA2F2E4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Top Header Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            shopName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001632),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E7EC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              shopCity.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF42474E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        todayStr,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF72777F)),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF006B5F),
                    child: Text(
                      shopName.isNotEmpty ? shopName.substring(0, 1).toUpperCase() : 'R',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEF1F4)),

            // Active Tab Content
            Expanded(child: tabs[_selectedIndex]),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        indicatorColor: const Color(0xFFA2F2E4).withValues(alpha: 0.5),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Items',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Challans',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
