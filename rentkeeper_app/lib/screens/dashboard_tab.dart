import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/challan.dart';
import '../services/storage_service.dart';
import '../widgets/challan_detail_dialog.dart';

class DashboardTab extends StatelessWidget {
  final StorageService storage;
  final VoidCallback onStateChanged;
  final VoidCallback onNewBooking;
  final VoidCallback onAddItem;
  final VoidCallback onAddCustomer;

  const DashboardTab({
    super.key,
    required this.storage,
    required this.onStateChanged,
    required this.onNewBooking,
    required this.onAddItem,
    required this.onAddCustomer,
  });

  String _formatCurrency(num amount) {
    return 'Rs. ${NumberFormat('#,##0').format(amount)}';
  }

  Future<void> _sendWhatsAppAlert(BuildContext context, String phone, String customer, String challanNumber) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = 'Salam $customer, this is a reminder regarding your overdue rental challan $challanNumber at Al-Rehman Rentals. Please arrange return or extension. Thank you!';
    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot launch WhatsApp for $cleanPhone')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate metrics
    final totalItems = storage.items.fold<int>(0, (sum, i) => sum + i.totalStock);
    final readyToDispatch = storage.items.fold<int>(0, (sum, i) => sum + i.availableStock);
    final activeChallans = storage.challans.where((c) => c.status == 'active').length;
    final overdueReturns = storage.challans.where((c) => c.isOverdue).length;

    final totalRevenue = storage.challans.fold<double>(0.0, (sum, c) => sum + c.paidAmount);
    final securityDeposits = storage.challans
        .where((c) => c.status == 'active')
        .fold<double>(0.0, (sum, c) => sum + c.securityDepositHeld);
    final outstandingDues = storage.challans
        .where((c) => c.status != 'cancelled')
        .fold<double>(0.0, (sum, c) => sum + c.balancePending);
    final outstandingClients = storage.customers.where((c) => c.outstandingBalance > 0).length;

    final scheduleList = storage.challans
        .where((c) => c.status == 'active')
        .toList()
      ..sort((a, b) => a.scheduledReturnDate.compareTo(b.scheduledReturnDate));

    final readyPct = totalItems > 0 ? ((readyToDispatch / totalItems) * 100).round() : 100;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // KPI 2x2 Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _buildKpiCard(
              title: 'Total Equipment',
              badge: 'Asset Base',
              badgeColor: const Color(0xFFEEF1F4),
              badgeTextColor: const Color(0xFF42474E),
              value: '$totalItems',
              valueColor: const Color(0xFF001632),
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF001632),
            ),
            _buildKpiCard(
              title: 'Ready to Dispatch',
              badge: '$readyPct% Ready',
              badgeColor: const Color(0xFFA2F2E4).withValues(alpha: 0.4),
              badgeTextColor: const Color(0xFF006B5F),
              value: '$readyToDispatch',
              valueColor: const Color(0xFF006B5F),
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF006B5F),
            ),
            _buildKpiCard(
              title: 'Active Challans',
              badge: 'On Field',
              badgeColor: const Color(0xFFD9E3F8),
              badgeTextColor: const Color(0xFF001632),
              value: '$activeChallans',
              valueColor: const Color(0xFF001632),
              icon: Icons.outbox,
              iconColor: const Color(0xFF001632),
            ),
            _buildKpiCard(
              title: 'Overdue Returns',
              badge: overdueReturns > 0 ? 'Action Req' : 'Clear',
              badgeColor: overdueReturns > 0 ? const Color(0xFFFFDAD6) : const Color(0xFFA2F2E4).withValues(alpha: 0.4),
              badgeTextColor: overdueReturns > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF006B5F),
              value: overdueReturns < 10 ? '0$overdueReturns' : '$overdueReturns',
              valueColor: overdueReturns > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF006B5F),
              icon: Icons.warning_amber_rounded,
              iconColor: overdueReturns > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF006B5F),
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
                onTap: onNewBooking,
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
                onTap: onAddItem,
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
                onTap: onAddCustomer,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Revenue Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                    'Total Paid Revenue',
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
                      color: const Color(0xFFA2F2E4).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${storage.challans.where((c) => c.paidAmount > 0).length} Paid Challans',
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
                _formatCurrency(totalRevenue),
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
                          _formatCurrency(securityDeposits),
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
                  color: Colors.white.withValues(alpha: 0.1),
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
                      _formatCurrency(outstandingDues),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Across $outstandingClients clients with unpaid balance',
                      style: const TextStyle(color: Color(0xFFA2F2E4), fontSize: 11),
                    ),
                  ],
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
              '${scheduleList.length} Active',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF006B5F)),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (scheduleList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No active rental returns pending today!',
                style: TextStyle(color: Color(0xFF72777F), fontSize: 13),
              ),
            ),
          )
        else
          ...scheduleList.map((c) => _buildChallanCard(context, c)),

        const SizedBox(height: 20),
      ],
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
            color: Colors.black.withValues(alpha: 0.02),
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
    required VoidCallback onTap,
    bool border = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: border ? Border.all(color: const Color(0xFFE2E7EC)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
              style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallanCard(BuildContext context, Challan c) {
    final bool isOverdue = c.isOverdue;
    final firstItem = c.items.isNotEmpty ? c.items.first.itemName : 'General Equipment';
    final extraCount = c.items.length > 1 ? c.items.length - 1 : 0;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => ChallanDetailDialog(
            challan: c,
            onUpdated: onStateChanged,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isOverdue ? Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.5), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                      Icons.videocam_outlined,
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
                                '$firstItem${extraCount > 0 ? " +$extraCount more" : ""}',
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
                          '${c.customerName} • CNIC: ${c.customerCnic}',
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
                  color: isOverdue ? const Color(0xFFFFDAD6).withValues(alpha: 0.3) : const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Due: ${DateFormat('dd MMM, hh:mm a').format(c.scheduledReturnDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF42474E),
                      ),
                    ),
                    if (isOverdue)
                      ElevatedButton.icon(
                        onPressed: () => _sendWhatsAppAlert(context, c.customerPhone, c.customerName, c.challanNumber),
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
                        c.balancePending > 0 ? 'Bal: ${_formatCurrency(c.balancePending)}' : 'Cleared',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: c.balancePending > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF006B5F),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
