import 'package:flutter/material.dart';

void main() {
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
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isOnline = true;
  int _syncQueue = 0;

  // Live Metrics
  int _totalItems = 142;
  int _readyToDispatch = 98;
  int _activeChallans = 38;
  int _overdueReturns = 6;
  int _currentMonthRevenue = 485200;
  double _momGrowth = 18.4;
  int _securityDeposits = 185000;
  int _outstandingDues = 64500;
  int _outstandingClients = 4;

  final List<Map<String, dynamic>> _challans = [
    {
      'id': 'chal_8821',
      'challanNumber': 'RK-8821',
      'customerName': 'Usman Farooq',
      'customerPhone': '+923001234567',
      'customerCnic': '35202-*******-1',
      'itemName': 'Sony FX3 Cinema Kit',
      'additionalItems': 2,
      'category': 'cameras',
      'isOverdue': true,
      'dueLabel': '14:00, Yesterday',
      'balancePending': 14500,
    },
    {
      'id': 'chal_8822',
      'challanNumber': 'RK-8822',
      'customerName': 'Hamza Malik (Creative Pixel)',
      'customerPhone': '+923219876543',
      'customerCnic': '35201-*******-3',
      'itemName': 'Aputure 600d Pro Light',
      'additionalItems': 0,
      'category': 'lighting',
      'isOverdue': false,
      'dueLabel': '18:00, Today',
      'balancePending': 8000,
    },
    {
      'id': 'chal_8823',
      'challanNumber': 'RK-8823',
      'customerName': 'Zeeshan Ali',
      'customerPhone': '+923334567890',
      'customerCnic': '35202-*******-7',
      'itemName': 'DJI Ronin RS3 Gimbal',
      'additionalItems': 1,
      'category': 'cameras',
      'isOverdue': false,
      'dueLabel': '11:00, Tomorrow',
      'balancePending': 0,
    },
  ];

  String _formatCurrency(num amount) {
    return 'Rs. ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _sendWhatsAppAlert(String challanNumber, String customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF001632),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFA2F2E4), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'WhatsApp overdue reminder sent to $customer ($challanNumber)!',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Offline/Online Sync Banner
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
                      color: _isOnline ? const Color(0xFFA2F2E4) : const Color(0xFFBA1A1A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline ? 'ONLINE • SQLite Synced' : 'OFFLINE MODE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sync Queue: $_syncQueue',
                    style: const TextStyle(
                      color: Color(0xFFA2F2E4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Al-Rehman Rentals',
                            style: TextStyle(
                              fontSize: 18,
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
                            child: const Text(
                              'LAHORE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF42474E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Friday, 23 October 2026',
                        style: TextStyle(fontSize: 12, color: Color(0xFF72777F)),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF006B5F),
                    child: const Text(
                      'AR',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Dashboard Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // KPI 2x2 Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _buildKpiCard(
                        title: 'Total Equipment',
                        badge: 'Asset Base',
                        badgeColor: const Color(0xFFEEF1F4),
                        badgeTextColor: const Color(0xFF42474E),
                        value: '$_totalItems',
                        valueColor: const Color(0xFF001632),
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFF001632),
                      ),
                      _buildKpiCard(
                        title: 'Ready to Dispatch',
                        badge: '${((_readyToDispatch / _totalItems) * 100).round()}% Ready',
                        badgeColor: const Color(0xFFA2F2E4).withOpacity(0.4),
                        badgeTextColor: const Color(0xFF006B5F),
                        value: '$_readyToDispatch',
                        valueColor: const Color(0xFF006B5F),
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF006B5F),
                      ),
                      _buildKpiCard(
                        title: 'Active Challans',
                        badge: 'On Field',
                        badgeColor: const Color(0xFFD9E3F8),
                        badgeTextColor: const Color(0xFF001632),
                        value: '$_activeChallans',
                        valueColor: const Color(0xFF001632),
                        icon: Icons.outbox,
                        iconColor: const Color(0xFF001632),
                      ),
                      _buildKpiCard(
                        title: 'Overdue Returns',
                        badge: 'Action Req',
                        badgeColor: const Color(0xFFFFDAD6),
                        badgeTextColor: const Color(0xFFBA1A1A),
                        value: '0$_overdueReturns',
                        valueColor: const Color(0xFFBA1A1A),
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFBA1A1A),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'New Booking',
                          sub: 'Challan',
                          icon: Icons.add_task,
                          bg: const Color(0xFF006B5F),
                          fg: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Add Item',
                          sub: 'Inventory',
                          icon: Icons.add_box_outlined,
                          bg: const Color(0xFF001632),
                          fg: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Add Client',
                          sub: 'Customer',
                          icon: Icons.person_add_alt_1_outlined,
                          bg: Colors.white,
                          fg: const Color(0xFF001632),
                          border: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Revenue & Liability Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'October Revenue',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF72777F),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA2F2E4).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+$_momGrowth% MoM',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006B5F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatCurrency(_currentMonthRevenue),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001632),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Security Deposits Demarcation Liability Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E7EC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF42474E)),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Security Deposits Held',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001632)),
                                    ),
                                    Text(
                                      'Refundable Collateral Liability',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF72777F)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(_securityDeposits),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001632)),
                                  ),
                                  const Text(
                                    'Non-Revenue',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF72777F)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Outstanding Dues Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001632),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.payments_outlined, color: Color(0xFFA2F2E4), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OUTSTANDING DUES',
                                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              Text(
                                _formatCurrency(_outstandingDues),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Across $_outstandingClients clients',
                                style: const TextStyle(color: Color(0xFFA2F2E4), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: const Text('Collect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006B5F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Return Schedule & Follow-ups Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: Color(0xFF001632)),
                          SizedBox(width: 6),
                          Text(
                            'Return Schedule & Follow-ups',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF001632)),
                          ),
                        ],
                      ),
                      Text(
                        '${_challans.length} Expected',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF006B5F)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Challans List
                  ..._challans.map((c) => _buildChallanCard(c)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        indicatorColor: const Color(0xFFA2F2E4).withOpacity(0.5),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Items',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Challans',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: iconColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF72777F)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String sub,
    required IconData icon,
    required Color bg,
    required Color fg,
    bool border = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: border ? Border.all(color: const Color(0xFFE2E7EC)) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: fg),
            textAlign: TextAlign.center,
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 9, color: fg.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildChallanCard(Map<String, dynamic> c) {
    final bool isOverdue = c['isOverdue'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue ? Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.4), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOverdue ? const Color(0xFFFFDAD6) : const Color(0xFFF3F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    c['category'] == 'lighting' ? Icons.lightbulb_outline : Icons.videocam_outlined,
                    color: isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF001632),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${c['itemName']}${c['additionalItems'] > 0 ? " +${c['additionalItems']} more" : ""}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001632)),
                            ),
                          ),
                          if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA1A1A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c['customerName']} • CNIC: ${c['customerCnic']}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF72777F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isOverdue ? const Color(0xFFFFDAD6).withOpacity(0.3) : const Color(0xFFF3F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${c['dueLabel']}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF42474E),
                    ),
                  ),
                  if (isOverdue)
                    ElevatedButton.icon(
                      onPressed: () => _sendWhatsAppAlert(c['challanNumber'], c['customerName']),
                      icon: const Icon(Icons.chat_bubble_outline, size: 14),
                      label: const Text('WhatsApp Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    Text(
                      c['balancePending'] > 0 ? 'Bal: ${_formatCurrency(c['balancePending'])}' : 'Cleared',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c['balancePending'] > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF006B5F),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
