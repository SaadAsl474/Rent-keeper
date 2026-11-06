import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsTab extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onStateChanged;

  const SettingsTab({super.key, required this.storage, required this.onStateChanged});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late TextEditingController _shopNameController;
  late TextEditingController _cityController;
  late TextEditingController _operatorController;
  late TextEditingController _serverUrlController;

  bool _isTestingSync = false;
  String _syncStatusMessage = 'Ready (Offline SQLite / Local Storage)';

  @override
  void initState() {
    super.initState();
    final shop = widget.storage.shop;
    _shopNameController = TextEditingController(text: shop['name'] ?? 'Al-Rehman Rentals');
    _cityController = TextEditingController(text: shop['city'] ?? 'Lahore');
    _operatorController = TextEditingController(text: shop['operator'] ?? 'Tariq Sahib');
    _serverUrlController = TextEditingController(
      text: shop['serverUrl'] ?? 'http://10.0.2.2:8080/api/v1',
    );
  }

  Future<void> _saveShopSettings() async {
    widget.storage.shop['name'] = _shopNameController.text.trim();
    widget.storage.shop['city'] = _cityController.text.trim();
    widget.storage.shop['operator'] = _operatorController.text.trim();
    widget.storage.shop['serverUrl'] = _serverUrlController.text.trim();
    await widget.storage.saveShop();
    widget.storage.refreshApiClient();
    widget.onStateChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF006B5F),
          content: Text('Shop profile & sync settings saved!'),
        ),
      );
    }
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _isTestingSync = true;
      _syncStatusMessage = 'Connecting to backend server...';
    });

    final connected = await widget.storage.testConnection();
    if (connected) {
      // Pull fresh data from the server
      await widget.storage.syncFromServer();
      setState(() {
        _syncStatusMessage =
            'Connected! Server online. Data synced.\nLast sync: ${widget.storage.lastSyncTime}';
      });
    } else {
      setState(() {
        _syncStatusMessage =
            'Could not reach server.\nRunning safely in standalone offline mode.';
      });
    }

    setState(() => _isTestingSync = false);
  }

  Future<void> _syncNow() async {
    setState(() {
      _isTestingSync = true;
      _syncStatusMessage = 'Syncing with server...';
    });

    final success = await widget.storage.syncFromServer();
    if (success) {
      setState(() {
        _syncStatusMessage =
            'Sync complete! ${widget.storage.items.length} items, ${widget.storage.customers.length} customers, ${widget.storage.challans.length} challans.\nLast sync: ${widget.storage.lastSyncTime}';
      });
    } else {
      setState(() {
        _syncStatusMessage = 'Server unreachable. Working offline.\nPending sync: ${widget.storage.pendingSyncCount} mutations queued.';
      });
    }

    setState(() => _isTestingSync = false);
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all equipment items, customers, and challans from local storage.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await widget.storage.clearAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (!mounted) return;
              widget.onStateChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF006B5F),
                  content: Text('All local data cleared successfully!'),
                ),
              );
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Identity Card
            Container(
              padding: const EdgeInsets.all(16),
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
                  const Row(
                    children: [
                      Icon(Icons.storefront, color: Color(0xFF001632)),
                      SizedBox(width: 8),
                      Text('Rental Enterprise Profile',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(labelText: 'Shop / Business Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City / District', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _operatorController,
                          decoration: const InputDecoration(labelText: 'Store Manager', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001632),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saveShopSettings,
                      child: const Text('Save Business Info'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Server & Network Sync
            Container(
              padding: const EdgeInsets.all(16),
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
                  const Row(
                    children: [
                      Icon(Icons.sync_alt, color: Color(0xFF006B5F)),
                      SizedBox(width: 8),
                      Text('Remote Server & Database Sync',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The app works 100% offline with zero server required. If you run the Dart backend (bin/server.dart) on your local network or server, specify the endpoint below:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF72777F)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _serverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'API Endpoint (e.g. http://192.168.1.100:8080/api/v1)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingSync ? null : _testServerConnection,
                          icon: _isTestingSync
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_find, size: 18),
                          label: const Text('Test Connection'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingSync ? null : _syncNow,
                          icon: const Icon(Icons.sync, size: 18),
                          label: const Text('Sync Now'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006B5F),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _saveShopSettings,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save URL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _syncStatusMessage,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF44474E), fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Demo Data & Danger Zone
            Container(
              padding: const EdgeInsets.all(16),
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
                  const Row(
                    children: [
                      Icon(Icons.restart_alt, color: Color(0xFFBA1A1A)),
                      SizedBox(width: 8),
                      Text('Database Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clear all equipment, customers, and challan records from local storage.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF72777F)),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBA1A1A),
                        side: const BorderSide(color: Color(0xFFBA1A1A)),
                      ),
                      onPressed: _confirmResetData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Clear All Local Data'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Version details
            const Center(
              child: Column(
                children: [
                  Text('RentKeeper Operational Precision',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001632), fontSize: 13)),
                  SizedBox(height: 2),
                  Text('Version 1.0.0+1 • Offline First Architecture',
                      style: TextStyle(color: Color(0xFF72777F), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
