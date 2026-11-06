import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/challan.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../services/storage_service.dart';

class CreateChallanScreen extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateChallanScreen({super.key, required this.onCreated});

  @override
  State<CreateChallanScreen> createState() => _CreateChallanScreenState();
}

class _CreateChallanScreenState extends State<CreateChallanScreen> {
  final StorageService _storage = StorageService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0');

  late String _challanNumber;
  Customer? _selectedCustomer;
  final List<_SelectedBookingItem> _selectedItems = [];

  DateTime _dispatchDate = DateTime.now();
  DateTime _scheduledReturnDate = DateTime.now().add(const Duration(days: 2));

  final TextEditingController _securityDepositController = TextEditingController(text: '20000');
  final TextEditingController _advancePaidController = TextEditingController(text: '0');
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _challanNumber = _storage.getNextChallanNumber();
    if (_storage.customers.isNotEmpty) {
      _selectedCustomer = _storage.customers.first;
    }
  }

  double get _totalRentalAmount {
    double sum = 0;
    for (final item in _selectedItems) {
      sum += item.item.dailyRate * item.quantity * item.days;
    }
    return sum;
  }

  double get _balancePending {
    final advance = double.tryParse(_advancePaidController.text) ?? 0.0;
    return (_totalRentalAmount - advance).clamp(0.0, double.infinity);
  }

  void _addItemToBooking() {
    RentalItem? chosenItem;
    int qty = 1;
    int days = 2;

    final availableItems = _storage.items.where((i) => i.availableStock > 0).toList();
    if (availableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items currently available in inventory!')),
      );
      return;
    }
    chosenItem = availableItems.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Equipment to Challan', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RentalItem>(
                initialValue: chosenItem,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Equipment', border: OutlineInputBorder()),
                items: availableItems
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            '${item.name} (${item.availableStock} in stock)',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => chosenItem = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: qty,
                      decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                      items: List.generate(
                        (chosenItem?.availableStock ?? 1).clamp(1, 100),
                        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                      ),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => qty = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: days,
                      decoration: const InputDecoration(labelText: 'Days', border: OutlineInputBorder()),
                      items: List.generate(30, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} d'))),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => days = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (chosenItem != null)
                Text(
                  'Rate: Rs. ${_currencyFormat.format(chosenItem!.dailyRate)}/day  •  Total: Rs. ${_currencyFormat.format(chosenItem!.dailyRate * qty * days)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF006B5F)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B5F),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (chosenItem != null) {
                  setState(() {
                    _selectedItems.add(_SelectedBookingItem(
                      item: chosenItem!,
                      quantity: qty,
                      days: days,
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add to List'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndDispatch() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a customer first!')),
      );
      return;
    }
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the booking!')),
      );
      return;
    }

    final deposit = double.tryParse(_securityDepositController.text) ?? 0.0;
    final advance = double.tryParse(_advancePaidController.text) ?? 0.0;

    final challan = Challan(
      id: 'chal_${DateTime.now().millisecondsSinceEpoch}',
      challanNumber: _challanNumber,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      customerPhone: _selectedCustomer!.phone,
      customerCnic: _selectedCustomer!.cnic,
      items: _selectedItems
          .map((si) => ChallanItem(
                itemId: si.item.id,
                itemName: si.item.name,
                quantity: si.quantity,
                dailyRate: si.item.dailyRate,
                days: si.days,
                totalRent: si.item.dailyRate * si.quantity * si.days,
              ))
          .toList(),
      dispatchDate: _dispatchDate,
      scheduledReturnDate: _scheduledReturnDate,
      status: 'active',
      totalAmount: _totalRentalAmount,
      securityDepositHeld: deposit,
      paidAmount: advance,
      balancePending: (_totalRentalAmount - advance).clamp(0.0, double.infinity),
      venue: _venueController.text.trim(),
      notes: _notesController.text.trim(),
    );

    await _storage.createChallan(challan);
    widget.onCreated();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF006B5F),
          content: Text('Challan $_challanNumber generated & inventory dispatched!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Rental Booking (Challan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF001632),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challan Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF001632),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Challan Serial Number', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    _challanNumber,
                    style: const TextStyle(color: Color(0xFFA2F2E4), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Selector
            const Text('Customer / Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<Customer>(
              initialValue: _selectedCustomer,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: _storage.customers
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (${c.phone})', overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCustomer = val);
              },
            ),

            const SizedBox(height: 16),

            // Date Pickers Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dispatchDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _dispatchDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E7EC)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dispatch Date', style: TextStyle(fontSize: 10, color: Color(0xFF72777F))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF001632)),
                              const SizedBox(width: 6),
                              Text(DateFormat('dd MMM yyyy').format(_dispatchDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _scheduledReturnDate,
                        firstDate: _dispatchDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _scheduledReturnDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E7EC)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Return Due Date', style: TextStyle(fontSize: 10, color: Color(0xFF72777F))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.event_repeat, size: 14, color: Color(0xFF006B5F)),
                              const SizedBox(width: 6),
                              Text(DateFormat('dd MMM yyyy').format(_scheduledReturnDate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF006B5F))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selected Equipment List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selected Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton.icon(
                  onPressed: _addItemToBooking,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Equipment'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF006B5F)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_selectedItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E7EC), style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: Color(0xFF72777F), size: 32),
                    SizedBox(height: 8),
                    Text('No items added yet. Tap "Add Equipment" above.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF72777F))),
                  ],
                ),
              )
            else
              ..._selectedItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final si = entry.value;
                final total = si.item.dailyRate * si.quantity * si.days;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E7EC)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(si.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '${si.quantity} unit(s)  •  ${si.days} day(s) @ Rs. ${_currencyFormat.format(si.item.dailyRate)}/d',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF72777F)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs. ${_currencyFormat.format(total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF001632)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFBA1A1A), size: 20),
                        onPressed: () => setState(() => _selectedItems.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Financial Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Rental Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'Rs. ${_currencyFormat.format(_totalRentalAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF001632)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: _securityDepositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refundable Security Deposit (Rs.)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _advancePaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Advance Paid / Cash Received (Rs.)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Balance Due:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        'Rs. ${_currencyFormat.format(_balancePending)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _balancePending > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF006B5F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Venue and Notes
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Shoot / Event Venue (e.g. Lahore Fort, DHA Raya)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Terms / Handover Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B5F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _confirmAndDispatch,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Confirm & Dispatch Challan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SelectedBookingItem {
  final RentalItem item;
  final int quantity;
  final int days;

  _SelectedBookingItem({required this.item, required this.quantity, required this.days});
}
