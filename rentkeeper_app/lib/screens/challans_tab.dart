import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../widgets/challan_detail_dialog.dart';
import 'create_challan_screen.dart';

class ChallansTab extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onStateChanged;

  const ChallansTab({super.key, required this.storage, required this.onStateChanged});

  @override
  State<ChallansTab> createState() => _ChallansTabState();
}

class _ChallansTabState extends State<ChallansTab> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0');
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _statusFilters = ['All', 'Active', 'Overdue', 'Completed'];

  String _formatRs(num amount) => 'Rs. ${_currencyFormat.format(amount)}';

  @override
  Widget build(BuildContext context) {
    var filtered = widget.storage.challans.where((c) {
      final matchesSearch = c.challanNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.customerPhone.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (_selectedStatus == 'Active') {
        matchesStatus = c.status == 'active' && !c.isOverdue;
      } else if (_selectedStatus == 'Overdue') {
        matchesStatus = c.isOverdue;
      } else if (_selectedStatus == 'Completed') {
        matchesStatus = c.status == 'completed';
      }

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (q) => setState(() => _searchQuery = q),
                  decoration: InputDecoration(
                    hintText: 'Search by Challan # (RK-xxxx), client, phone...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    filled: true,
                    fillColor: const Color(0xFFF3F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((st) {
                      final isSelected = _selectedStatus == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(st),
                          selected: isSelected,
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedStatus = st);
                          },
                          selectedColor: const Color(0xFF001632),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF44474E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFFEEF1F4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Rental Challans',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF72777F)),
                ),
                Text(
                  'Pending Collections: ${_formatRs(filtered.fold<double>(0.0, (s, c) => s + c.balancePending))}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFBA1A1A)),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF72777F)),
                        const SizedBox(height: 12),
                        const Text('No challans found in this category',
                            style: TextStyle(color: Color(0xFF72777F), fontSize: 14)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => CreateChallanScreen(
                                  onCreated: widget.onStateChanged,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Booking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006B5F),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final c = filtered[idx];
                      final isOverdue = c.isOverdue;
                      final isCompleted = c.status == 'completed';

                      return InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ChallanDetailDialog(
                              challan: c,
                              onUpdated: widget.onStateChanged,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isOverdue
                                ? Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.5), width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.challanNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF001632),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? const Color(0xFFA2F2E4).withValues(alpha: 0.5)
                                              : (isOverdue ? const Color(0xFFFFDAD6) : const Color(0xFFD9E3F8)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isCompleted ? 'COMPLETED' : (isOverdue ? 'OVERDUE' : 'ACTIVE'),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted
                                                ? const Color(0xFF006B5F)
                                                : (isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF001632)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatRs(c.totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF72777F)),
                                  const SizedBox(width: 4),
                                  Text(c.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Text('(${c.customerPhone})',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF72777F))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${c.items.length} item(s): ${c.items.map((i) => i.itemName).join(', ')}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF44474E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F5F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Due: ${DateFormat('dd MMM yyyy, hh:mm a').format(c.scheduledReturnDate)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF72777F),
                                      ),
                                    ),
                                    Text(
                                      c.balancePending > 0
                                          ? 'Balance Due: ${_formatRs(c.balancePending)}'
                                          : 'Paid in Full',
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
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF006B5F),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => CreateChallanScreen(
                onCreated: widget.onStateChanged,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Booking', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
