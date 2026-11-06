import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../services/storage_service.dart';
import '../widgets/challan_detail_dialog.dart';

class CustomersTab extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onStateChanged;

  const CustomersTab({super.key, required this.storage, required this.onStateChanged});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0');
  String _searchQuery = '';

  String _formatRs(num amount) => 'Rs. ${_currencyFormat.format(amount)}';

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = 'Salam $name, this is Al-Rehman Rentals regarding your rental account and bookings.';
    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddEditCustomerDialog([Customer? existing]) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final cnicController = TextEditingController(text: existing?.cnic ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Client' : 'Add New Client', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (e.g. +92 300 1234567) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cnicController,
                decoration: const InputDecoration(
                  labelText: 'CNIC (e.g. 35201-xxxxxxx-x) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Studio / Office Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Account Notes / Verification Details',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B5F),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final cnic = cnicController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter name and phone number!')),
                );
                return;
              }

              if (isEditing) {
                existing.name = name;
                existing.phone = phone;
                existing.cnic = cnic;
                existing.address = addressController.text.trim();
                existing.notes = notesController.text.trim();
                await widget.storage.updateCustomer(existing);
              } else {
                final newCust = Customer(
                  id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  phone: phone,
                  cnic: cnic,
                  address: addressController.text.trim(),
                  notes: notesController.text.trim(),
                );
                await widget.storage.addCustomer(newCust);
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (!mounted) return;
              widget.onStateChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF006B5F),
                  content: Text(isEditing ? 'Client updated!' : '$name registered successfully!'),
                ),
              );
            },
            child: Text(isEditing ? 'Save Changes' : 'Register Client'),
          ),
        ],
      ),
    );
  }

  void _showCustomerLedger(Customer customer) {
    final clientChallans = widget.storage.challans.where((c) => c.customerId == customer.id).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('CNIC: ${customer.cnic} • Phone: ${customer.phone}',
                        style: const TextStyle(color: Color(0xFF72777F), fontSize: 12)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF001632),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding Dues:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    _formatRs(customer.outstandingBalance),
                    style: TextStyle(
                      color: customer.outstandingBalance > 0 ? const Color(0xFFFFDAD6) : const Color(0xFFA2F2E4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Booking History & Challans',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001632))),
            const SizedBox(height: 8),
            Expanded(
              child: clientChallans.isEmpty
                  ? const Center(child: Text('No challans recorded for this client yet.'))
                  : ListView.builder(
                      itemCount: clientChallans.length,
                      itemBuilder: (context, i) {
                        final ch = clientChallans[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(ch.challanNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${DateFormat('dd MMM yyyy').format(ch.dispatchDate)} • ${ch.items.length} item(s)'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatRs(ch.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                ch.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: ch.status == 'completed'
                                      ? const Color(0xFF006B5F)
                                      : (ch.isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF001632)),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => ChallanDetailDialog(
                                challan: ch,
                                onUpdated: widget.onStateChanged,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filtered = widget.storage.customers.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.cnic.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'Search clients by name, mobile, CNIC...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: const Color(0xFFF3F5F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Registered Clients',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF72777F)),
                ),
                Text(
                  'Active Ledger accounts',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF006B5F), fontWeight: FontWeight.w600),
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
                        const Icon(Icons.people_outline, size: 48, color: Color(0xFF72777F)),
                        const SizedBox(height: 12),
                        const Text('No clients found', style: TextStyle(color: Color(0xFF72777F), fontSize: 14)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditCustomerDialog(),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Client'),
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
                      final hasDues = c.outstandingBalance > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
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
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF001632),
                                      child: Text(
                                        c.name.isNotEmpty ? c.name.substring(0, 1).toUpperCase() : 'C',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF001632),
                                              ),
                                            ),
                                            if (c.isVerified) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.verified, size: 16, color: Color(0xFF006B5F)),
                                            ],
                                          ],
                                        ),
                                        Text('CNIC: ${c.cnic}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF72777F))),
                                      ],
                                    ),
                                  ],
                                ),
                                if (hasDues)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDAD6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Due: ${_formatRs(c.outstandingBalance)}',
                                      style: const TextStyle(
                                        color: Color(0xFFBA1A1A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            if (c.address.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF72777F)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(c.address,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF44474E))),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${c.totalBookings} Bookings  •  ${c.activeRentalsCount} on rent',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF72777F)),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF001632)),
                                      tooltip: 'Call Client',
                                      onPressed: () => _makeCall(c.phone),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF006B5F)),
                                      tooltip: 'WhatsApp',
                                      onPressed: () => _sendWhatsApp(c.phone, c.name),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.receipt_long, size: 20, color: Color(0xFF001632)),
                                      tooltip: 'View Ledger',
                                      onPressed: () => _showCustomerLedger(c),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
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
        onPressed: () => _showAddEditCustomerDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
