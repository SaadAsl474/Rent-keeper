import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/storage_service.dart';

class ItemsTab extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onStateChanged;

  const ItemsTab({super.key, required this.storage, required this.onStateChanged});

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0');
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Cameras', 'Lighting', 'Sound/PA', 'Power', 'Rigging'];

  String _formatRs(num amount) => 'Rs. ${_currencyFormat.format(amount)}';

  void _showAddEditItemDialog([RentalItem? existingItem]) {
    final isEditing = existingItem != null;
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    String category = existingItem?.category ?? 'Cameras';
    final rateController = TextEditingController(
      text: existingItem != null ? existingItem.dailyRate.toStringAsFixed(0) : '',
    );
    final valueController = TextEditingController(
      text: existingItem != null ? existingItem.replacementValue.toStringAsFixed(0) : '',
    );
    final stockController = TextEditingController(
      text: existingItem != null ? existingItem.totalStock.toString() : '3',
    );
    final barcodeController = TextEditingController(text: existingItem?.barcode ?? '');
    final serialController = TextEditingController(text: existingItem?.serialNumber ?? '');
    final descController = TextEditingController(text: existingItem?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Equipment' : 'Add New Equipment',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categories.sublist(1).contains(category) ? category : 'Cameras',
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: _categories
                      .sublist(1)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Daily Rate (Rs.) *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Units *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Replacement / Asset Value (Rs.)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: serialController,
                        decoration: const InputDecoration(labelText: 'Serial No', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Kit Description', border: OutlineInputBorder()),
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
                final rate = double.tryParse(rateController.text) ?? 0.0;
                final total = int.tryParse(stockController.text) ?? 1;
                final value = double.tryParse(valueController.text) ?? (rate * 30);

                if (name.isEmpty || rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid item name and daily rate!')),
                  );
                  return;
                }

                if (isEditing) {
                  existingItem.name = name;
                  existingItem.category = category;
                  existingItem.dailyRate = rate;
                  existingItem.totalStock = total;
                  existingItem.availableStock = (total - existingItem.rentedStock).clamp(0, total);
                  existingItem.replacementValue = value;
                  existingItem.barcode = barcodeController.text.trim();
                  existingItem.serialNumber = serialController.text.trim();
                  existingItem.description = descController.text.trim();
                  await widget.storage.updateItem(existingItem);
                } else {
                  final newItem = RentalItem(
                    id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    category: category,
                    dailyRate: rate,
                    totalStock: total,
                    availableStock: total,
                    rentedStock: 0,
                    replacementValue: value,
                    barcode: barcodeController.text.trim(),
                    serialNumber: serialController.text.trim(),
                    description: descController.text.trim(),
                  );
                  await widget.storage.addItem(newItem);
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (!mounted) return;
                widget.onStateChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF006B5F),
                    content: Text(isEditing ? 'Item updated!' : '$name added to inventory!'),
                  ),
                );
              },
              child: Text(isEditing ? 'Save Changes' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(RentalItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Equipment?'),
        content: Text('Are you sure you want to remove "${item.name}" from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white),
            onPressed: () async {
              await widget.storage.deleteItem(item.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (!mounted) return;
              widget.onStateChanged();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filtered = widget.storage.items.where((i) {
      final matchesSearch = i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.barcode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.serialNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || i.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCat;
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
                    hintText: 'Search by equipment name, barcode, SN...',
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
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedCategory = cat);
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

          // Total Items Count Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Items Listed',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF72777F)),
                ),
                Text(
                  'Asset Base: ${_formatRs(widget.storage.items.fold<double>(0.0, (s, i) => s + (i.replacementValue * i.totalStock)))}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF006B5F)),
                ),
              ],
            ),
          ),

          // Equipment List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF72777F)),
                        const SizedBox(height: 12),
                        const Text('No equipment matches your search',
                            style: TextStyle(color: Color(0xFF72777F), fontSize: 14)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditItemDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Equipment'),
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
                      final item = filtered[idx];
                      final isOutOfStock = item.availableStock == 0;

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: isOutOfStock ? const Color(0xFFFFDAD6) : const Color(0xFFEEF1F4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item.category.toLowerCase() == 'cameras'
                                        ? Icons.videocam_outlined
                                        : (item.category.toLowerCase() == 'power'
                                            ? Icons.power_outlined
                                            : Icons.lightbulb_outline),
                                    color: isOutOfStock ? const Color(0xFFBA1A1A) : const Color(0xFF001632),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001632)),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E7EC),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.category.toUpperCase(),
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF42474E)),
                                            ),
                                          ),
                                          if (item.barcode.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Text(item.barcode, style: const TextStyle(fontSize: 10, color: Color(0xFF72777F))),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF72777F)),
                                  onSelected: (val) {
                                    if (val == 'edit') _showAddEditItemDialog(item);
                                    if (val == 'delete') _confirmDelete(item);
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit Equipment')),
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete Item', style: TextStyle(color: Color(0xFFBA1A1A)))),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Stock availability status bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.totalStock > 0 ? (item.availableStock / item.totalStock) : 0,
                                backgroundColor: const Color(0xFFE2E7EC),
                                color: isOutOfStock
                                    ? const Color(0xFFBA1A1A)
                                    : (item.availableStock == item.totalStock
                                        ? const Color(0xFF006B5F)
                                        : const Color(0xFF001632)),
                                minHeight: 6,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.availableStock} of ${item.totalStock} available (${item.rentedStock} on rent)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isOutOfStock ? const Color(0xFFBA1A1A) : const Color(0xFF44474E),
                                  ),
                                ),
                                Text(
                                  '${_formatRs(item.dailyRate)}/day',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF006B5F),
                                  ),
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
        onPressed: () => _showAddEditItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
