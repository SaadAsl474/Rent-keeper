import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/challan.dart';
import '../services/storage_service.dart';

class ChallanDetailDialog extends StatefulWidget {
  final Challan challan;
  final VoidCallback onUpdated;

  const ChallanDetailDialog({
    super.key,
    required this.challan,
    required this.onUpdated,
  });

  @override
  State<ChallanDetailDialog> createState() => _ChallanDetailDialogState();
}

class _ChallanDetailDialogState extends State<ChallanDetailDialog> {
  final StorageService _storage = StorageService();
  final NumberFormat _currencyFormat = NumberFormat('#,##0');

  String _formatRs(num amount) => 'Rs. ${_currencyFormat.format(amount)}';

  Future<void> _sendWhatsApp(String phone, String text) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open WhatsApp for $cleanPhone')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp error: $e')),
        );
      }
    }
  }

  void _showReturnDialog() {
    final lateFeeController = TextEditingController(
      text: widget.challan.isOverdue ? '4500' : '0',
    );
    final damageFeeController = TextEditingController(text: '0');
    final notesController = TextEditingController(text: 'Equipment returned in good condition.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Checking in ${widget.challan.challanNumber} for ${widget.challan.customerName}. Items will be released back into available inventory.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF44474E)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lateFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Late Fee (Rs.)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_off_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: damageFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Damage Assessment Fee (Rs.)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Inspection Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B5F),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final lateFee = double.tryParse(lateFeeController.text) ?? 0.0;
              final damageFee = double.tryParse(damageFeeController.text) ?? 0.0;

              await _storage.completeReturn(
                widget.challan.id,
                lateFee: lateFee,
                damageFee: damageFee,
                returnNotes: notesController.text,
              );

              if (ctx.mounted) {
                Navigator.pop(ctx); // Close prompt
              }
              if (!mounted) return;
              Navigator.pop(context); // Close detail dialog
              widget.onUpdated();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF006B5F),
                  content: Text('${widget.challan.challanNumber} marked as Returned! Inventory updated.'),
                ),
              );
            },
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  void _showCollectPaymentDialog() {
    final amountController = TextEditingController(
      text: widget.challan.balancePending.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance Due: ${_formatRs(widget.challan.balancePending)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (Rs.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001632),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final paid = double.tryParse(amountController.text) ?? 0.0;
              if (paid > 0) {
                await _storage.recordPayment(widget.challan.id, paid);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (!mounted) return;
                setState(() {});
                widget.onUpdated();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment of ${_formatRs(paid)} recorded!')),
                );
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.challan;
    final isCompleted = ch.status == 'completed';
    final isOverdue = ch.isOverdue;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? const Color(0xFFBA1A1A)
                      : (isCompleted ? const Color(0xFF006B5F) : const Color(0xFF001632)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ch.challanNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isCompleted
                              ? 'COMPLETED / RETURNED'
                              : (isOverdue ? 'ACTION REQUIRED • OVERDUE' : 'ACTIVE ON FIELD'),
                          style: const TextStyle(
                            color: Color(0xFFA2F2E4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin, size: 20, color: Color(0xFF001632)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ch.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF001632),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF006B5F)),
                                tooltip: 'WhatsApp Customer',
                                onPressed: () {
                                  final msg =
                                      'Salam ${ch.customerName}, this is regarding your rental challan ${ch.challanNumber} at Al-Rehman Rentals. Balance: ${_formatRs(ch.balancePending)}. Scheduled return: ${DateFormat('dd MMM, hh:mm a').format(ch.scheduledReturnDate)}. Thank you!';
                                  _sendWhatsApp(ch.customerPhone, msg);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Phone: ${ch.customerPhone} • CNIC: ${ch.customerCnic}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF72777F))),
                          if (ch.venue.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Venue: ${ch.venue}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF44474E))),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dispatch & Return Schedule
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            'Dispatch Date',
                            DateFormat('dd MMM, hh:mm a').format(ch.dispatchDate),
                            Icons.outbox,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoTile(
                            'Scheduled Return',
                            DateFormat('dd MMM, hh:mm a').format(ch.scheduledReturnDate),
                            Icons.schedule,
                            isWarning: isOverdue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Items List
                    const Text(
                      'Rented Equipment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001632)),
                    ),
                    const SizedBox(height: 8),
                    ...ch.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9FF),
                          border: Border.all(color: const Color(0xFFE2E7EC)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF1F4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2, size: 16, color: Color(0xFF001632)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  Text(
                                    'Qty: ${item.quantity}  •  ${item.days} days @ ${_formatRs(item.dailyRate)}/day',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF72777F)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatRs(item.totalRent),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Financial Summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildFinanceRow('Total Rental Amount', _formatRs(ch.totalAmount)),
                          if (ch.securityDepositHeld > 0)
                            _buildFinanceRow('Security Deposit (Refundable)', _formatRs(ch.securityDepositHeld),
                                isHighlight: true),
                          if (ch.lateFee > 0)
                            _buildFinanceRow('Late / Penalty Fee', _formatRs(ch.lateFee), isDanger: true),
                          _buildFinanceRow('Amount Paid', _formatRs(ch.paidAmount)),
                          const Divider(height: 16),
                          _buildFinanceRow(
                            'Balance Pending',
                            _formatRs(ch.balancePending),
                            isBold: true,
                            isDanger: ch.balancePending > 0,
                          ),
                        ],
                      ),
                    ),

                    if (ch.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes, size: 16, color: Color(0xFF8D6E63)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ch.notes,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Action Buttons Row
                    Row(
                      children: [
                        if (!isCompleted) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006B5F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _showReturnDialog,
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Return Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (ch.balancePending > 0) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001632),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _showCollectPaymentDialog,
                              icon: const Icon(Icons.payments_outlined, size: 18),
                              label: const Text('Collect Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildInfoTile(String title, String val, IconData icon, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFDAD6).withValues(alpha: 0.4) : const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(10),
        border: isWarning ? Border.all(color: const Color(0xFFBA1A1A)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isWarning ? const Color(0xFFBA1A1A) : const Color(0xFF72777F)),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: isWarning ? const Color(0xFFBA1A1A) : const Color(0xFF72777F)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isWarning ? const Color(0xFFBA1A1A) : const Color(0xFF001632),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value,
      {bool isBold = false, bool isHighlight = false, bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF44474E),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDanger
                  ? const Color(0xFFBA1A1A)
                  : (isHighlight ? const Color(0xFF006B5F) : const Color(0xFF001632)),
            ),
          ),
        ],
      ),
    );
  }
}
