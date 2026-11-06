// RentKeeper Backend Server
// A REST API server for rental business management.
// Uses dart:io HttpServer and JSON file storage — zero external dependencies.
//
// Usage: dart run server.dart
// Default port: 8080

import 'dart:io';
import 'dart:convert';
import 'dart:async';

// ---------------------------------------------------------------------------
// Data Store — JSON file-backed persistence
// ---------------------------------------------------------------------------

class DataStore {
  final String dataDir;
  final String itemsFile;
  final String customersFile;
  final String challansFile;
  final String shopFile;

  DataStore({required this.dataDir})
      : itemsFile = '$dataDir/items.json',
        customersFile = '$dataDir/customers.json',
        challansFile = '$dataDir/challans.json',
        shopFile = '$dataDir/shop.json';

  Future<void> init() async {
    final dir = Directory(dataDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    // Create empty files if they don't exist
    await _ensureFile(itemsFile, []);
    await _ensureFile(customersFile, []);
    await _ensureFile(challansFile, []);
    await _ensureFile(shopFile, {
      'name': 'Al-Rehman Rentals',
      'tagline': 'RentKeeper Operational Precision',
      'city': 'Lahore',
      'operator': 'Tariq Sahib',
      'currency': 'Rs.',
      'serverUrl': 'http://10.0.2.2:8080/api/v1',
    });
  }

  Future<void> _ensureFile(String path, dynamic defaultValue) async {
    final file = File(path);
    if (!file.existsSync()) {
      await file.writeAsString(jsonEncode(defaultValue));
    }
  }

  // --- Items ---
  Future<List<Map<String, dynamic>>> getItems() async =>
      _readList(itemsFile);

  Future<void> saveItems(List<Map<String, dynamic>> items) async =>
      _writeList(itemsFile, items);

  // --- Customers ---
  Future<List<Map<String, dynamic>>> getCustomers() async =>
      _readList(customersFile);

  Future<void> saveCustomers(List<Map<String, dynamic>> customers) async =>
      _writeList(customersFile, customers);

  // --- Challans ---
  Future<List<Map<String, dynamic>>> getChallans() async =>
      _readList(challansFile);

  Future<void> saveChallans(List<Map<String, dynamic>> challans) async =>
      _writeList(challansFile, challans);

  // --- Shop ---
  Future<Map<String, dynamic>> getShop() async {
    final file = File(shopFile);
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<void> saveShop(Map<String, dynamic> shop) async =>
      await File(shopFile).writeAsString(jsonEncode(shop));

  // --- Helpers ---
  Future<List<Map<String, dynamic>>> _readList(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    final list = jsonDecode(content) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _writeList(String path, List<Map<String, dynamic>> data) async =>
      await File(path).writeAsString(jsonEncode(data));
}

// ---------------------------------------------------------------------------
// HTTP Helpers
// ---------------------------------------------------------------------------

void _setCorsHeaders(HttpResponse res) {
  res.headers.set('Access-Control-Allow-Origin', '*');
  res.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Accept');
}

void _jsonResponse(HttpResponse res, {int status = 200, required Map<String, dynamic> body}) {
  res.statusCode = status;
  res.headers.contentType = ContentType.json;
  _setCorsHeaders(res);
  res.write(jsonEncode(body));
  res.close();
}

void _ok(HttpResponse res, {dynamic data}) =>
    _jsonResponse(res, status: 200, body: {'success': true, 'data': data});

void _error(HttpResponse res, String message, {int status = 400}) =>
    _jsonResponse(res, status: status, body: {'success': false, 'error': message});

Future<Map<String, dynamic>> _readBody(HttpRequest req) async {
  final content = await utf8.decoder.bind(req).join();
  if (content.isEmpty) return {};
  return jsonDecode(content) as Map<String, dynamic>;
}

String _extractId(String path, String prefix) {
  // Extract the ID segment from a path like /api/v1/items/item_123
  final afterPrefix = path.substring(prefix.length);
  final slashIdx = afterPrefix.indexOf('/');
  return slashIdx == -1 ? afterPrefix : afterPrefix.substring(0, slashIdx);
}

// ---------------------------------------------------------------------------
// Business Logic — mirrors the Flutter StorageService operations
// ---------------------------------------------------------------------------

Future<void> _createChallanLogic(DataStore store, Map<String, dynamic> challan) async {
  final items = await store.getItems();
  final customers = await store.getCustomers();
  final challans = await store.getChallans();

  // Update item stock
  final itemList = challan['items'] as List? ?? [];
  for (final ci in itemList) {
    final itemMap = ci as Map<String, dynamic>;
    final itemId = itemMap['itemId'] as String?;
    final itemIndex = items.indexWhere((i) => i['id'] == itemId);
    if (itemIndex != -1) {
      final item = items[itemIndex];
      final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 1;
      item['rentedStock'] = ((item['rentedStock'] as num?)?.toInt() ?? 0) + quantity;
      final totalStock = (item['totalStock'] as num?)?.toInt() ?? 0;
      item['availableStock'] = (totalStock - (item['rentedStock'] as num)).clamp(0, totalStock);
      item['status'] = item['availableStock'] == 0
          ? 'rented_out'
          : (item['rentedStock'] > 0 ? 'partially_rented' : 'available');
      item['updatedAt'] = DateTime.now().toIso8601String();
    }
  }

  // Update customer stats
  final customerId = challan['customerId'] as String?;
  final custIndex = customers.indexWhere((c) => c['id'] == customerId);
  if (custIndex != -1) {
    customers[custIndex]['totalBookings'] = ((customers[custIndex]['totalBookings'] as num?)?.toInt() ?? 0) + 1;
    customers[custIndex]['activeRentalsCount'] = ((customers[custIndex]['activeRentalsCount'] as num?)?.toInt() ?? 0) + 1;
    customers[custIndex]['outstandingBalance'] =
        ((customers[custIndex]['outstandingBalance'] as num?)?.toDouble() ?? 0.0) +
        ((challan['balancePending'] as num?)?.toDouble() ?? 0.0);
    customers[custIndex]['updatedAt'] = DateTime.now().toIso8601String();
  }

  challan['updatedAt'] = DateTime.now().toIso8601String();
  challans.insert(0, challan);

  await store.saveItems(items);
  await store.saveCustomers(customers);
  await store.saveChallans(challans);
}

Future<void> _returnChallanLogic(
  DataStore store,
  String challanId, {
  double lateFee = 0.0,
  double damageFee = 0.0,
  String returnNotes = '',
}) async {
  final items = await store.getItems();
  final customers = await store.getCustomers();
  final challans = await store.getChallans();

  final index = challans.indexWhere((c) => c['id'] == challanId);
  if (index == -1) return;

  final ch = challans[index];
  ch['status'] = 'completed';
  ch['actualReturnDate'] = DateTime.now().toIso8601String();
  ch['lateFee'] = lateFee;
  final existingNotes = ch['notes'] as String? ?? '';
  ch['notes'] = '$existingNotes\n[Return Check-in]: $returnNotes (Late fee: Rs. $lateFee, Damage: Rs. $damageFee)'.trim();
  ch['totalAmount'] = ((ch['totalAmount'] as num?)?.toDouble() ?? 0.0) + lateFee + damageFee;
  final paid = (ch['paidAmount'] as num?)?.toDouble() ?? 0.0;
  final total = (ch['totalAmount'] as num).toDouble();
  ch['balancePending'] = (total - paid).clamp(0.0, double.infinity);

  // Restore item stock
  final itemList = ch['items'] as List? ?? [];
  for (final ci in itemList) {
    final itemMap = ci as Map<String, dynamic>;
    final itemId = itemMap['itemId'] as String?;
    final itemIndex = items.indexWhere((i) => i['id'] == itemId);
    if (itemIndex != -1) {
      final item = items[itemIndex];
      final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 1;
      final totalStock = (item['totalStock'] as num?)?.toInt() ?? 0;
      item['rentedStock'] = ((item['rentedStock'] as num?)?.toInt() ?? 0) - quantity;
      item['rentedStock'] = (item['rentedStock'] as num).clamp(0, totalStock);
      item['availableStock'] = (totalStock - (item['rentedStock'] as num)).clamp(0, totalStock);
      item['status'] = item['availableStock'] == totalStock
          ? 'available'
          : (item['availableStock'] > 0 ? 'partially_rented' : 'rented_out');
      item['updatedAt'] = DateTime.now().toIso8601String();
    }
  }

  // Update customer active rentals count
  final customerId = ch['customerId'] as String?;
  final custIndex = customers.indexWhere((c) => c['id'] == customerId);
  if (custIndex != -1) {
    final activeCount = (customers[custIndex]['activeRentalsCount'] as num?)?.toInt() ?? 0;
    customers[custIndex]['activeRentalsCount'] = (activeCount - 1).clamp(0, 999);
    customers[custIndex]['updatedAt'] = DateTime.now().toIso8601String();
  }

  ch['updatedAt'] = DateTime.now().toIso8601String();

  await store.saveItems(items);
  await store.saveCustomers(customers);
  await store.saveChallans(challans);
}

Future<void> _recordPaymentLogic(DataStore store, String challanId, double amountPaid) async {
  final challans = await store.getChallans();
  final customers = await store.getCustomers();

  final index = challans.indexWhere((c) => c['id'] == challanId);
  if (index == -1) return;

  final ch = challans[index];
  ch['paidAmount'] = ((ch['paidAmount'] as num?)?.toDouble() ?? 0.0) + amountPaid;
  final total = (ch['totalAmount'] as num?)?.toDouble() ?? 0.0;
  final paid = (ch['paidAmount'] as num).toDouble();
  final prevBalance = (ch['balancePending'] as num?)?.toDouble() ?? 0.0;
  ch['balancePending'] = (total - paid).clamp(0.0, double.infinity);

  // Update customer outstanding balance
  final customerId = ch['customerId'] as String?;
  final custIndex = customers.indexWhere((c) => c['id'] == customerId);
  if (custIndex != -1) {
    final diff = prevBalance - (ch['balancePending'] as num).toDouble();
    customers[custIndex]['outstandingBalance'] =
        ((customers[custIndex]['outstandingBalance'] as num?)?.toDouble() ?? 0.0) - diff;
    customers[custIndex]['outstandingBalance'] =
        (customers[custIndex]['outstandingBalance'] as num).clamp(0.0, double.infinity);
    customers[custIndex]['updatedAt'] = DateTime.now().toIso8601String();
  }

  ch['updatedAt'] = DateTime.now().toIso8601String();

  await store.saveChallans(challans);
  await store.saveCustomers(customers);
}

// ---------------------------------------------------------------------------
// Request Router
// ---------------------------------------------------------------------------

Future<void> handleRequest(HttpRequest req, DataStore store) async {
  final path = req.uri.path;
  final method = req.method;

  // CORS preflight
  if (method == 'OPTIONS') {
    _jsonResponse(req.response, status: 204, body: {});
    return;
  }

  // Route: /api/v1/dashboard
  if (path == '/api/v1/dashboard' && method == 'GET') {
    await _handleDashboard(req, store);
    return;
  }

  // Route: /api/v1/shop
  if (path == '/api/v1/shop' && method == 'GET') {
    _ok(req.response, data: await store.getShop());
    return;
  }
  if (path == '/api/v1/shop' && method == 'PUT') {
    final body = await _readBody(req);
    await store.saveShop(body);
    _ok(req.response, data: body);
    return;
  }

  // Route: /api/v1/items
  if (path == '/api/v1/items' && method == 'GET') {
    await _handleGetItems(req, store);
    return;
  }
  if (path == '/api/v1/items' && method == 'POST') {
    await _handleCreateItem(req, store);
    return;
  }

  // Route: /api/v1/items/{id}
  if (path.startsWith('/api/v1/items/') && method == 'PUT') {
    await _handleUpdateItem(req, store, _extractId(path, '/api/v1/items/'));
    return;
  }
  if (path.startsWith('/api/v1/items/') && method == 'DELETE') {
    await _handleDeleteItem(req, store, _extractId(path, '/api/v1/items/'));
    return;
  }

  // Route: /api/v1/customers
  if (path == '/api/v1/customers' && method == 'GET') {
    _ok(req.response, data: await store.getCustomers());
    return;
  }
  if (path == '/api/v1/customers' && method == 'POST') {
    await _handleCreateCustomer(req, store);
    return;
  }

  // Route: /api/v1/customers/{id}
  if (path.startsWith('/api/v1/customers/') && method == 'PUT') {
    await _handleUpdateCustomer(req, store, _extractId(path, '/api/v1/customers/'));
    return;
  }
  if (path.startsWith('/api/v1/customers/') && method == 'DELETE') {
    await _handleDeleteCustomer(req, store, _extractId(path, '/api/v1/customers/'));
    return;
  }

  // Route: /api/v1/challans
  if (path == '/api/v1/challans' && method == 'GET') {
    _ok(req.response, data: await store.getChallans());
    return;
  }
  if (path == '/api/v1/challans' && method == 'POST') {
    await _handleCreateChallan(req, store);
    return;
  }

  // Route: /api/v1/challans/{id}/return
  if (path.contains('/return') && path.startsWith('/api/v1/challans/') && method == 'POST') {
    final challanId = path.substring('/api/v1/challans/'.length).replaceAll('/return', '');
    await _handleReturnChallan(req, store, challanId);
    return;
  }

  // Route: /api/v1/challans/{id}/payment
  if (path.contains('/payment') && path.startsWith('/api/v1/challans/') && method == 'POST') {
    final challanId = path.substring('/api/v1/challans/'.length).replaceAll('/payment', '');
    await _handleRecordPayment(req, store, challanId);
    return;
  }

  // Route: /api/v1/challans/{id}/whatsapp-alert
  if (path.contains('/whatsapp-alert') && path.startsWith('/api/v1/challans/') && method == 'POST') {
    final challanId = path.substring('/api/v1/challans/'.length).replaceAll('/whatsapp-alert', '');
    final challans = await store.getChallans();
    final ch = challans.firstWhere((c) => c['id'] == challanId, orElse: () => {});
    _ok(req.response, data: {'status': 'alert_queued', 'challanNumber': ch['challanNumber'] ?? ''});
    return;
  }

  // Route: /api/v1/sync/push
  if (path == '/api/v1/sync/push' && method == 'POST') {
    await _handleSyncPush(req, store);
    return;
  }

  // Route: /api/v1/sync/pull
  if (path == '/api/v1/sync/pull' && method == 'GET') {
    _ok(req.response, data: {
      'items': await store.getItems(),
      'customers': await store.getCustomers(),
      'challans': await store.getChallans(),
      'shop': await store.getShop(),
      'serverTime': DateTime.now().toIso8601String(),
    });
    return;
  }

  // 404
  _error(req.response, 'Endpoint not found: $method $path', status: 404);
}

// ---------------------------------------------------------------------------
// Endpoint Handlers
// ---------------------------------------------------------------------------

Future<void> _handleDashboard(HttpRequest req, DataStore store) async {
  final items = await store.getItems();
  final customers = await store.getCustomers();
  final challans = await store.getChallans();
  final shop = await store.getShop();

  final totalItems = items.fold<int>(0, (sum, i) => sum + ((i['totalStock'] as num?)?.toInt() ?? 0));
  final readyToDispatch = items.fold<int>(0, (sum, i) => sum + ((i['availableStock'] as num?)?.toInt() ?? 0));
  final activeChallans = challans.where((c) => c['status'] == 'active').length;
  final overdueReturns = challans.where((c) {
    if (c['status'] == 'completed' || c['status'] == 'cancelled') return false;
    final returnDate = DateTime.tryParse(c['scheduledReturnDate'] as String? ?? '');
    return returnDate != null && DateTime.now().isAfter(returnDate);
  }).length;

  final totalRevenue = challans.fold<double>(0.0, (sum, c) => sum + ((c['paidAmount'] as num?)?.toDouble() ?? 0.0));
  final securityDeposits = challans
      .where((c) => c['status'] == 'active')
      .fold<double>(0.0, (sum, c) => sum + ((c['securityDepositHeld'] as num?)?.toDouble() ?? 0.0));
  final outstandingDues = challans
      .where((c) => c['status'] != 'cancelled')
      .fold<double>(0.0, (sum, c) => sum + ((c['balancePending'] as num?)?.toDouble() ?? 0.0));
  final outstandingClients = customers.where((c) => ((c['outstandingBalance'] as num?)?.toDouble() ?? 0.0) > 0).length;

  _ok(req.response, data: {
    'shop': shop,
    'metrics': {
      'totalItems': totalItems,
      'readyToDispatch': readyToDispatch,
      'activeChallans': activeChallans,
      'overdueReturns': overdueReturns,
      'totalRevenue': totalRevenue,
      'securityDepositsHeld': securityDeposits,
      'outstandingDues': outstandingDues,
      'outstandingClients': outstandingClients,
      'totalCustomers': customers.length,
      'totalChallans': challans.length,
    },
    'recentChallans': challans.take(10).toList(),
    'sync': {
      'status': 'Online',
      'pendingQueue': 0,
      'serverTime': DateTime.now().toIso8601String(),
    },
  });
}

Future<void> _handleGetItems(HttpRequest req, DataStore store) async {
  final items = await store.getItems();
  final params = req.uri.queryParameters;
  var filtered = items;

  if (params.containsKey('category') && params['category'] != 'All') {
    filtered = filtered.where((i) => i['category'] == params['category']).toList();
  }
  if (params.containsKey('status')) {
    filtered = filtered.where((i) => i['status'] == params['status']).toList();
  }
  if (params.containsKey('query') && params['query']!.isNotEmpty) {
    final q = params['query']!.toLowerCase();
    filtered = filtered.where((i) {
      final name = (i['name'] as String? ?? '').toLowerCase();
      final barcode = (i['barcode'] as String? ?? '').toLowerCase();
      final serial = (i['serialNumber'] as String? ?? '').toLowerCase();
      return name.contains(q) || barcode.contains(q) || serial.contains(q);
    }).toList();
  }

  _ok(req.response, data: filtered);
}

Future<void> _handleCreateItem(HttpRequest req, DataStore store) async {
  final body = await _readBody(req);
  body['id'] ??= 'item_${DateTime.now().millisecondsSinceEpoch}';
  body['rentedStock'] ??= 0;
  body['condition'] ??= 'good';
  body['status'] ??= 'available';
  body['description'] ??= '';
  body['imageUrl'] ??= '';
  body['updatedAt'] = DateTime.now().toIso8601String();

  final items = await store.getItems();
  items.insert(0, body);
  await store.saveItems(items);
  _ok(req.response, data: body);
}

Future<void> _handleUpdateItem(HttpRequest req, DataStore store, String id) async {
  final body = await _readBody(req);
  body['updatedAt'] = DateTime.now().toIso8601String();

  final items = await store.getItems();
  final index = items.indexWhere((i) => i['id'] == id);
  if (index == -1) {
    _error(req.response, 'Item not found', status: 404);
    return;
  }
  items[index] = {...items[index], ...body};
  await store.saveItems(items);
  _ok(req.response, data: items[index]);
}

Future<void> _handleDeleteItem(HttpRequest req, DataStore store, String id) async {
  final items = await store.getItems();
  items.removeWhere((i) => i['id'] == id);
  await store.saveItems(items);
  _ok(req.response, data: {'deleted': id});
}

Future<void> _handleCreateCustomer(HttpRequest req, DataStore store) async {
  final body = await _readBody(req);
  body['id'] ??= 'cust_${DateTime.now().millisecondsSinceEpoch}';
  body['outstandingBalance'] ??= 0.0;
  body['activeRentalsCount'] ??= 0;
  body['totalBookings'] ??= 0;
  body['isVerified'] ??= 1;
  body['notes'] ??= '';
  body['address'] ??= '';
  body['updatedAt'] = DateTime.now().toIso8601String();

  final customers = await store.getCustomers();
  customers.insert(0, body);
  await store.saveCustomers(customers);
  _ok(req.response, data: body);
}

Future<void> _handleUpdateCustomer(HttpRequest req, DataStore store, String id) async {
  final body = await _readBody(req);
  body['updatedAt'] = DateTime.now().toIso8601String();

  final customers = await store.getCustomers();
  final index = customers.indexWhere((c) => c['id'] == id);
  if (index == -1) {
    _error(req.response, 'Customer not found', status: 404);
    return;
  }
  customers[index] = {...customers[index], ...body};
  await store.saveCustomers(customers);
  _ok(req.response, data: customers[index]);
}

Future<void> _handleDeleteCustomer(HttpRequest req, DataStore store, String id) async {
  final customers = await store.getCustomers();
  customers.removeWhere((c) => c['id'] == id);
  await store.saveCustomers(customers);
  _ok(req.response, data: {'deleted': id});
}

Future<void> _handleCreateChallan(HttpRequest req, DataStore store) async {
  final body = await _readBody(req);
  body['id'] ??= 'chal_${DateTime.now().millisecondsSinceEpoch}';
  body['status'] ??= 'active';
  body['lateFee'] ??= 0.0;
  body['actualReturnDate'] = null;
  body['updatedAt'] = DateTime.now().toIso8601String();

  await _createChallanLogic(store, body);
  _ok(req.response, data: body);
}

Future<void> _handleReturnChallan(HttpRequest req, DataStore store, String challanId) async {
  final body = await _readBody(req);
  final lateFee = (body['lateFee'] as num?)?.toDouble() ?? 0.0;
  final damageFee = (body['damageFee'] as num?)?.toDouble() ?? 0.0;
  final notes = body['notes'] as String? ?? '';

  await _returnChallanLogic(store, challanId, lateFee: lateFee, damageFee: damageFee, returnNotes: notes);

  final challans = await store.getChallans();
  final ch = challans.firstWhere((c) => c['id'] == challanId, orElse: () => {});
  _ok(req.response, data: ch);
}

Future<void> _handleRecordPayment(HttpRequest req, DataStore store, String challanId) async {
  final body = await _readBody(req);
  final amount = (body['amount'] as num?)?.toDouble() ?? 0.0;

  if (amount <= 0) {
    _error(req.response, 'Payment amount must be greater than 0');
    return;
  }

  await _recordPaymentLogic(store, challanId, amount);

  final challans = await store.getChallans();
  final ch = challans.firstWhere((c) => c['id'] == challanId, orElse: () => {});
  _ok(req.response, data: ch);
}

Future<void> _handleSyncPush(HttpRequest req, DataStore store) async {
  final body = await _readBody(req);
  final mutations = body['mutations'] as List? ?? [];
  final acceptedIds = <String>[];

  for (final mut in mutations) {
    final m = mut as Map<String, dynamic>;
    final mutationId = m['mutationId'] as String? ?? '';
    final action = m['action'] as String? ?? '';
    final entityType = m['entityType'] as String? ?? '';
    final payload = m['payload'] as Map<String, dynamic>? ?? {};

    try {
      if (entityType == 'challan' && action == 'create') {
        await _createChallanLogic(store, payload);
      } else if (entityType == 'challan' && action == 'return') {
        await _returnChallanLogic(store, m['entityId'] as String? ?? '',
            lateFee: (payload['lateFee'] as num?)?.toDouble() ?? 0.0,
            damageFee: (payload['damageFee'] as num?)?.toDouble() ?? 0.0,
            returnNotes: payload['notes'] as String? ?? '');
      } else if (entityType == 'challan' && action == 'payment') {
        await _recordPaymentLogic(store, m['entityId'] as String? ?? '',
            (payload['amount'] as num?)?.toDouble() ?? 0.0);
      } else if (entityType == 'item' && action == 'create') {
        await _handleCreateItem(req, store);
      } else if (entityType == 'customer' && action == 'create') {
        await _handleCreateCustomer(req, store);
      }
      acceptedIds.add(mutationId);
    } catch (e) {
      // Skip failed mutations
      stderr.writeln('Sync mutation failed: $e');
    }
  }

  _ok(req.response, data: {
    'processed': mutations.length,
    'acceptedIds': acceptedIds,
    'rejected': mutations.length - acceptedIds.length,
  });
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final dataDir = Platform.environment['DATA_DIR'] ?? 'data';

  final store = DataStore(dataDir: dataDir);
  await store.init();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('');
  stdout.writeln('=========================================================');
  stdout.writeln('  RentKeeper Backend Server');
  stdout.writeln('  Listening on http://0.0.0.0:$port');
  stdout.writeln('  API Base: http://localhost:$port/api/v1');
  stdout.writeln('  Android Emulator: http://10.0.2.2:$port/api/v1');
  stdout.writeln('  Data directory: ${Directory(dataDir).absolute.path}');
  stdout.writeln('=========================================================');
  stdout.writeln('');

  await for (final req in server) {
    try {
      await handleRequest(req, store);
    } catch (e, stack) {
      stderr.writeln('Request error: $e');
      stderr.writeln(stack);
      try {
        _error(req.response, 'Internal server error: $e', status: 500);
      } catch (_) {
        // Response already closed by handler
      }
    }
  }
}
