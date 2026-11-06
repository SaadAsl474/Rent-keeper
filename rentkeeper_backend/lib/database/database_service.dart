import 'dart:convert';
import 'dart:io';
import '../config/app_config.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../models/challan.dart';
import '../models/dashboard_metrics.dart';
import '../models/sync_item.dart';
import 'seed_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final Map<String, Item> _items = {};
  final Map<String, Customer> _customers = {};
  final Map<String, Challan> _challans = {};
  Map<String, dynamic> _shop = {};
  final List<Map<String, dynamic>> _syncLog = [];

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final dbFile = File(AppConfig.databasePath);
    if (await dbFile.exists()) {
      try {
        final content = await dbFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        _shop = Map<String, dynamic>.from(json['shop'] as Map? ?? SeedData.shop);

        final itemsList = (json['items'] as List<dynamic>? ?? [])
            .map((e) => Item.fromMap(Map<String, dynamic>.from(e as Map)));
        for (var item in itemsList) {
          _items[item.id] = item;
        }

        final customersList = (json['customers'] as List<dynamic>? ?? [])
            .map((e) => Customer.fromMap(Map<String, dynamic>.from(e as Map)));
        for (var customer in customersList) {
          _customers[customer.id] = customer;
        }

        final challansList = (json['challans'] as List<dynamic>? ?? [])
            .map((e) => Challan.fromMap(Map<String, dynamic>.from(e as Map)));
        for (var challan in challansList) {
          _challans[challan.id] = challan;
        }

        print('[Database] Loaded ${_items.length} items, ${_customers.length} customers, ${_challans.length} challans from ${AppConfig.databasePath}');
        _initialized = true;
        return;
      } catch (e) {
        print('[Database] Warning: Failed to parse existing DB file ($e). Re-seeding fresh data.');
      }
    }

    // First run or corrupt file -> Seed from defaults
    _shop = Map<String, dynamic>.from(SeedData.shop);
    for (var item in SeedData.getItems()) {
      _items[item.id] = item;
    }
    for (var customer in SeedData.getCustomers()) {
      _customers[customer.id] = customer;
    }
    for (var challan in SeedData.getChallans()) {
      _challans[challan.id] = challan;
    }

    _initialized = true;
    await persist();
    print('[Database] Initialized with Seed Data (${_items.length} items, ${_customers.length} customers, ${_challans.length} challans)');
  }

  Future<void> persist() async {
    try {
      final dbFile = File(AppConfig.databasePath);
      final parentDir = dbFile.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      final payload = {
        'version': AppConfig.appVersion,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'shop': _shop,
        'items': _items.values.map((i) => i.toMap()).toList(),
        'customers': _customers.values.map((c) => c.toMap()).toList(),
        'challans': _challans.values.map((ch) => ch.toMap()).toList(),
      };

      await dbFile.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    } catch (e) {
      print('[Database] Persistence error: $e');
    }
  }

  // --- SHOP PROFILE ---
  Map<String, dynamic> getShopProfile() => Map<String, dynamic>.from(_shop);

  Future<Map<String, dynamic>> updateShopProfile(Map<String, dynamic> updates) async {
    _shop.addAll(updates);
    await persist();
    return getShopProfile();
  }

  // --- DASHBOARD METRICS ---
  DashboardMetrics getDashboardMetrics() {
    // Dynamically calculate live status from active records
    final totalItemsCount = _items.length;
    final readyCount = _items.values.where((i) => i.status == 'available').length;
    final readyPct = totalItemsCount > 0 ? (readyCount / totalItemsCount * 100) : 0.0;

    final activeChallans = _challans.values.where((c) => c.status == 'dispatched' || c.status == 'overdue').length;
    final overdueChallans = _challans.values.where((c) => c.isOverdue || c.status == 'overdue').length;

    double liveDepositsHeld = 0.0;
    double liveOutstanding = 0.0;
    double liveRevenue = 0.0;
    for (var challan in _challans.values) {
      liveRevenue += challan.paidAmount;
      if (challan.status != 'completed') {
        liveDepositsHeld += challan.securityDepositHeld;
        liveOutstanding += challan.balancePending;
      }
    }

    return DashboardMetrics(
      totalItems: totalItemsCount,
      readyToDispatch: readyCount,
      activeChallans: activeChallans,
      overdueReturns: overdueChallans,
      readyPercentage: readyPct,
      currentMonthRevenue: liveRevenue,
      momGrowthPercentage: 0.0,
      securityDepositsHeld: liveDepositsHeld,
      outstandingDues: liveOutstanding,
      outstandingClientsCount: _customers.values.where((c) => c.outstandingBalance > 0).length,
      revenueTrend: [],
      syncQueueCount: _shop['syncQueueCount'] as int? ?? 0,
      lastSyncTime: 'Just now',
      shopName: _shop['name']?.toString() ?? 'Al-Rehman Rentals',
      shopCity: _shop['city']?.toString() ?? 'Lahore',
      operatorName: _shop['operator']?.toString() ?? 'Tariq Sahib',
    );
  }

  // --- ITEMS (INVENTORY) ---
  List<Item> getItems({String? category, String? status, String? query}) {
    var list = _items.values.toList();
    if (category != null && category.isNotEmpty && category != 'all') {
      list = list.where((i) => i.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      list = list.where((i) => i.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((i) =>
        i.name.toLowerCase().contains(q) ||
        i.barcode.toLowerCase().contains(q) ||
        i.serialNumber.toLowerCase().contains(q) ||
        i.category.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Item? getItemById(String id) => _items[id];

  Future<Item> createItem(Map<String, dynamic> data) async {
    final id = data['id']?.toString() ?? 'item_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = Item.fromMap({...data, 'id': id});
    _items[id] = newItem;
    await persist();
    return newItem;
  }

  Future<Item?> updateItem(String id, Map<String, dynamic> data) async {
    final existing = _items[id];
    if (existing == null) return null;

    final updated = existing.copyWith(
      name: data['name']?.toString(),
      category: data['category']?.toString(),
      barcode: data['barcode']?.toString(),
      serialNumber: data['serialNumber']?.toString(),
      dailyRate: (data['dailyRate'] as num?)?.toDouble(),
      replacementValue: (data['replacementValue'] as num?)?.toDouble(),
      totalStock: (data['totalStock'] as num?)?.toInt(),
      availableStock: (data['availableStock'] as num?)?.toInt(),
      rentedStock: (data['rentedStock'] as num?)?.toInt(),
      condition: data['condition']?.toString(),
      status: data['status']?.toString(),
      description: data['description']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
    );
    _items[id] = updated;
    await persist();
    return updated;
  }

  Future<bool> deleteItem(String id) async {
    final removed = _items.remove(id) != null;
    if (removed) await persist();
    return removed;
  }

  // --- CUSTOMERS ---
  List<Customer> getCustomers({String? query}) {
    var list = _customers.values.toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.phone.toLowerCase().contains(q) ||
        c.cnic.toLowerCase().contains(q) ||
        c.address.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Customer? getCustomerById(String id) => _customers[id];

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final id = data['id']?.toString() ?? 'cust_${DateTime.now().millisecondsSinceEpoch}';
    final newCust = Customer.fromMap({...data, 'id': id});
    _customers[id] = newCust;
    await persist();
    return newCust;
  }

  Future<Customer?> updateCustomer(String id, Map<String, dynamic> data) async {
    final existing = _customers[id];
    if (existing == null) return null;

    final updated = existing.copyWith(
      name: data['name']?.toString(),
      phone: data['phone']?.toString(),
      cnic: data['cnic']?.toString(),
      address: data['address']?.toString(),
      outstandingBalance: (data['outstandingBalance'] as num?)?.toDouble(),
      activeRentalsCount: (data['activeRentalsCount'] as num?)?.toInt(),
      totalBookings: (data['totalBookings'] as num?)?.toInt(),
      isVerified: data['isVerified'] as bool?,
      notes: data['notes']?.toString(),
    );
    _customers[id] = updated;
    await persist();
    return updated;
  }

  // --- CHALLANS (BOOKINGS & DISPATCHES) ---
  List<Challan> getChallans({String? status, String? customerId, bool? overdueOnly}) {
    var list = _challans.values.toList();
    if (status != null && status.isNotEmpty && status != 'all') {
      list = list.where((c) => c.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (customerId != null && customerId.isNotEmpty) {
      list = list.where((c) => c.customerId == customerId).toList();
    }
    if (overdueOnly == true) {
      list = list.where((c) => c.isOverdue || c.status == 'overdue').toList();
    }
    list.sort((a, b) => b.dispatchDate.compareTo(a.dispatchDate));
    return list;
  }

  Challan? getChallanById(String id) => _challans[id];

  Future<Challan> createChallan(Map<String, dynamic> data) async {
    final id = data['id']?.toString() ?? 'chal_${DateTime.now().millisecondsSinceEpoch}';
    final challanNum = data['challanNumber']?.toString() ?? 'RK-${1000 + _challans.length + 1}';

    final newChallan = Challan.fromMap({
      ...data,
      'id': id,
      'challanNumber': challanNum,
    });
    _challans[id] = newChallan;

    // Adjust customer and item stock
    final customer = _customers[newChallan.customerId];
    if (customer != null) {
      _customers[newChallan.customerId] = customer.copyWith(
        activeRentalsCount: customer.activeRentalsCount + 1,
        totalBookings: customer.totalBookings + 1,
        outstandingBalance: customer.outstandingBalance + newChallan.balancePending,
      );
    }

    for (var itemRecord in newChallan.items) {
      final it = _items[itemRecord.itemId];
      if (it != null) {
        final newAvail = (it.availableStock - itemRecord.quantity).clamp(0, it.totalStock);
        final newRented = (it.rentedStock + itemRecord.quantity).clamp(0, it.totalStock);
        _items[itemRecord.itemId] = it.copyWith(
          availableStock: newAvail,
          rentedStock: newRented,
          status: newAvail == 0 ? 'rented' : 'partially_rented',
        );
      }
    }

    await persist();
    return newChallan;
  }

  Future<Challan?> checkInChallanReturn(String id, {double? damageFee, String? returnNotes}) async {
    final challan = _challans[id];
    if (challan == null) return null;

    final now = DateTime.now().toIso8601String();
    final updated = challan.copyWith(
      status: 'completed',
      actualReturnDate: now,
      securityDepositHeld: 0.0, // Refunded / cleared
      balancePending: 0.0,
      notes: returnNotes != null ? '${challan.notes}\nReturn Check-in: $returnNotes' : challan.notes,
    );
    _challans[id] = updated;

    // Restore item stocks
    for (var itemRecord in challan.items) {
      final it = _items[itemRecord.itemId];
      if (it != null) {
        final newAvail = (it.availableStock + itemRecord.quantity).clamp(0, it.totalStock);
        final newRented = (it.rentedStock - itemRecord.quantity).clamp(0, it.totalStock);
        _items[itemRecord.itemId] = it.copyWith(
          availableStock: newAvail,
          rentedStock: newRented,
          status: newAvail == it.totalStock ? 'available' : 'partially_rented',
        );
      }
    }

    // Update customer active count
    final customer = _customers[challan.customerId];
    if (customer != null) {
      _customers[challan.customerId] = customer.copyWith(
        activeRentalsCount: (customer.activeRentalsCount - 1).clamp(0, 999),
        outstandingBalance: (customer.outstandingBalance - challan.balancePending).clamp(0, 9999999),
      );
    }

    await persist();
    return updated;
  }

  // --- OFFLINE SYNC HANDSHAKE ---
  Future<Map<String, dynamic>> processSyncMutations(List<SyncMutation> mutations) async {
    final acceptedIds = <String>[];
    final rejected = <Map<String, dynamic>>[];

    for (var mutation in mutations) {
      try {
        if (mutation.entityType == 'item') {
          if (mutation.action == 'create' || mutation.action == 'update') {
            await createItem(mutation.payload);
          } else if (mutation.action == 'delete') {
            await deleteItem(mutation.entityId);
          }
        } else if (mutation.entityType == 'customer') {
          if (mutation.action == 'create' || mutation.action == 'update') {
            await createCustomer(mutation.payload);
          }
        } else if (mutation.entityType == 'challan') {
          if (mutation.action == 'create') {
            await createChallan(mutation.payload);
          } else if (mutation.action == 'return') {
            await checkInChallanReturn(mutation.entityId);
          }
        }
        acceptedIds.add(mutation.mutationId);
        _syncLog.add(mutation.toMap());
      } catch (err) {
        rejected.add({
          'mutationId': mutation.mutationId,
          'error': err.toString(),
        });
      }
    }

    _shop['syncQueueCount'] = 0;
    _shop['syncStatus'] = 'SQLite Ready • Synced just now';
    await persist();

    return {
      'processed': acceptedIds.length,
      'acceptedIds': acceptedIds,
      'rejected': rejected,
      'serverTimestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> pullChangesSince(String? sinceTimestamp) {
    DateTime? since;
    if (sinceTimestamp != null) {
      since = DateTime.tryParse(sinceTimestamp);
    }

    bool isNewer(String iso) {
      if (since == null) return true;
      final dt = DateTime.tryParse(iso);
      if (dt == null) return true;
      return dt.isAfter(since);
    }

    final changedItems = _items.values.where((i) => isNewer(i.updatedAt)).map((i) => i.toMap()).toList();
    final changedCustomers = _customers.values.where((c) => isNewer(c.updatedAt)).map((c) => c.toMap()).toList();
    final changedChallans = _challans.values.where((ch) => isNewer(ch.updatedAt)).map((ch) => ch.toMap()).toList();

    return {
      'serverTimestamp': DateTime.now().toUtc().toIso8601String(),
      'shop': getShopProfile(),
      'items': changedItems,
      'customers': changedCustomers,
      'challans': changedChallans,
    };
  }
}
