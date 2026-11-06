import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../models/challan.dart';
import 'api_client.dart';

class StorageService {
  static const String keyItems = 'rk_items';
  static const String keyCustomers = 'rk_customers';
  static const String keyChallans = 'rk_challans';
  static const String keyShop = 'rk_shop';
  static const String keyInitialized = 'rk_initialized';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // --- Offline-first data held in memory ---
  List<RentalItem> items = [];
  List<Customer> customers = [];
  List<Challan> challans = [];
  Map<String, dynamic> shop = {
    'name': 'Al-Rehman Rentals',
    'tagline': 'RentKeeper Operational Precision',
    'city': 'Lahore',
    'operator': 'Tariq Sahib',
    'currency': 'Rs.',
    'serverUrl': 'http://10.0.2.2:8080/api/v1',
  };

  // --- Sync state ---
  bool isOnline = false;
  int pendingSyncCount = 0;
  String lastSyncTime = 'Never';
  ApiClient? _apiClient;

  /// Lazily create / refresh the API client from the stored server URL.
  ApiClient _getApiClient() {
    final url = (shop['serverUrl'] as String?) ?? '';
    if (_apiClient == null || _apiClient!.baseUrl != url) {
      _apiClient = ApiClient(baseUrl: url);
    }
    return _apiClient!;
  }

  // ===========================================================================
  // Initialization
  // ===========================================================================

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(keyInitialized) ?? false;

    if (!isInitialized) {
      await initializeEmptyData();
    } else {
      await loadFromStorage();
    }

    // Attempt to pull fresh data from the backend (non-blocking on failure)
    await syncFromServer();
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final itemsRaw = prefs.getString(keyItems);
    if (itemsRaw != null) {
      final list = jsonDecode(itemsRaw) as List;
      items = list.map((e) => RentalItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    final customersRaw = prefs.getString(keyCustomers);
    if (customersRaw != null) {
      final list = jsonDecode(customersRaw) as List;
      customers = list.map((e) => Customer.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    final challansRaw = prefs.getString(keyChallans);
    if (challansRaw != null) {
      final list = jsonDecode(challansRaw) as List;
      challans = list.map((e) => Challan.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    final shopRaw = prefs.getString(keyShop);
    if (shopRaw != null) {
      shop = Map<String, dynamic>.from(jsonDecode(shopRaw));
    }
  }

  // ===========================================================================
  // Local persistence (SharedPreferences cache)
  // ===========================================================================

  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyItems, jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  Future<void> saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCustomers, jsonEncode(customers.map((c) => c.toJson()).toList()));
  }

  Future<void> saveChallans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyChallans, jsonEncode(challans.map((c) => c.toJson()).toList()));
  }

  Future<void> saveShop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyShop, jsonEncode(shop));
  }

  // ===========================================================================
  // Server sync
  // ===========================================================================

  /// Pull all data from the backend, replacing local cache.
  /// Sets [isOnline] to true on success, false on failure.
  Future<bool> syncFromServer() async {
    try {
      final api = _getApiClient();
      final data = await api.syncPull();
      isOnline = true;

      final serverItems = data['items'] as List? ?? [];
      items = serverItems.map((e) => RentalItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      final serverCustomers = data['customers'] as List? ?? [];
      customers = serverCustomers.map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      final serverChallans = data['challans'] as List? ?? [];
      challans = serverChallans.map((e) => Challan.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      final serverShop = data['shop'] as Map?;
      if (serverShop != null) {
        // Keep our local serverUrl, don't overwrite with server's
        final localUrl = shop['serverUrl'];
        shop = Map<String, dynamic>.from(serverShop);
        shop['serverUrl'] = localUrl;
      }

      // Persist the synced data locally
      await saveItems();
      await saveCustomers();
      await saveChallans();
      await saveShop();

      lastSyncTime = DateTime.now().toLocal().toString().substring(0, 19);
      pendingSyncCount = 0;
      return true;
    } catch (e) {
      isOnline = false;
      return false;
    }
  }

  /// Test whether the backend is reachable.
  Future<bool> testConnection() async {
    try {
      final api = _getApiClient();
      await api.getDashboard();
      isOnline = true;
      lastSyncTime = DateTime.now().toLocal().toString().substring(0, 19);
      return true;
    } catch (e) {
      isOnline = false;
      return false;
    }
  }

  /// Rebuild the API client after the server URL changes in settings.
  void refreshApiClient() {
    _apiClient = null;
  }

  // ===========================================================================
  // Item Operations (local + API push)
  // ===========================================================================

  Future<void> addItem(RentalItem item) async {
    items.insert(0, item);
    await saveItems();

    // Push to backend
    try {
      await _getApiClient().createItem(item.toJson());
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  Future<void> updateItem(RentalItem item) async {
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      await saveItems();
    }

    try {
      await _getApiClient().updateItem(item.id, item.toJson());
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  Future<void> deleteItem(String id) async {
    items.removeWhere((i) => i.id == id);
    await saveItems();

    try {
      await _getApiClient().deleteItem(id);
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  // ===========================================================================
  // Customer Operations (local + API push)
  // ===========================================================================

  Future<void> addCustomer(Customer customer) async {
    customers.insert(0, customer);
    await saveCustomers();

    try {
      await _getApiClient().createCustomer(customer.toJson());
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      customers[index] = customer;
      await saveCustomers();
    }

    try {
      await _getApiClient().updateCustomer(customer.id, customer.toJson());
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  Future<void> deleteCustomer(String id) async {
    customers.removeWhere((c) => c.id == id);
    await saveCustomers();

    try {
      await _getApiClient().deleteCustomer(id);
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  // ===========================================================================
  // Challan & Booking Operations (local + API push)
  // ===========================================================================

  Future<void> createChallan(Challan challan) async {
    challans.insert(0, challan);

    // Update item stock counts
    for (final ci in challan.items) {
      final itemIndex = items.indexWhere((it) => it.id == ci.itemId);
      if (itemIndex != -1) {
        final it = items[itemIndex];
        it.rentedStock += ci.quantity;
        it.availableStock = (it.totalStock - it.rentedStock).clamp(0, it.totalStock);
        it.status = it.availableStock == 0
            ? 'rented_out'
            : (it.rentedStock > 0 ? 'partially_rented' : 'available');
      }
    }
    await saveItems();

    // Update customer stats
    final custIndex = customers.indexWhere((c) => c.id == challan.customerId);
    if (custIndex != -1) {
      customers[custIndex].totalBookings += 1;
      customers[custIndex].activeRentalsCount += 1;
      customers[custIndex].outstandingBalance += challan.balancePending;
      await saveCustomers();
    }

    await saveChallans();

    // Push to backend (server handles its own stock + customer updates)
    try {
      await _getApiClient().createChallan(challan.toJson());
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  Future<void> completeReturn(String challanId, {
    double lateFee = 0.0,
    double damageFee = 0.0,
    String returnNotes = '',
  }) async {
    final index = challans.indexWhere((c) => c.id == challanId);
    if (index == -1) return;

    final ch = challans[index];
    ch.status = 'completed';
    ch.actualReturnDate = DateTime.now();
    ch.lateFee = lateFee;
    ch.notes = '${ch.notes}\n[Return Check-in]: $returnNotes (Late fee: Rs. $lateFee, Damage: Rs. $damageFee)'.trim();

    // Adjust balance if late fee was charged
    ch.totalAmount += lateFee + damageFee;
    ch.balancePending = (ch.totalAmount - ch.paidAmount).clamp(0.0, double.infinity);

    // Restore item stock
    for (final ci in ch.items) {
      final itemIndex = items.indexWhere((it) => it.id == ci.itemId);
      if (itemIndex != -1) {
        final it = items[itemIndex];
        it.rentedStock = (it.rentedStock - ci.quantity).clamp(0, it.totalStock);
        it.availableStock = (it.totalStock - it.rentedStock).clamp(0, it.totalStock);
        it.status = it.availableStock == it.totalStock
            ? 'available'
            : (it.availableStock > 0 ? 'partially_rented' : 'rented_out');
      }
    }
    await saveItems();

    // Update customer active rentals count
    final custIndex = customers.indexWhere((c) => c.id == ch.customerId);
    if (custIndex != -1) {
      customers[custIndex].activeRentalsCount =
          (customers[custIndex].activeRentalsCount - 1).clamp(0, 999);
      await saveCustomers();
    }

    await saveChallans();

    // Push to backend
    try {
      await _getApiClient().returnChallan(
        challanId,
        lateFee: lateFee,
        damageFee: damageFee,
        notes: returnNotes,
      );
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  Future<void> recordPayment(String challanId, double amountPaid) async {
    final index = challans.indexWhere((c) => c.id == challanId);
    if (index == -1) return;

    final ch = challans[index];
    ch.paidAmount += amountPaid;
    final prevBalance = ch.balancePending;
    ch.balancePending = (ch.totalAmount - ch.paidAmount).clamp(0.0, double.infinity);

    // Update customer outstanding balance
    final custIndex = customers.indexWhere((c) => c.id == ch.customerId);
    if (custIndex != -1) {
      final diff = prevBalance - ch.balancePending;
      customers[custIndex].outstandingBalance =
          (customers[custIndex].outstandingBalance - diff).clamp(0.0, double.infinity);
      await saveCustomers();
    }

    await saveChallans();

    // Push to backend
    try {
      await _getApiClient().recordPayment(challanId, amountPaid);
      isOnline = true;
    } catch (e) {
      isOnline = false;
      pendingSyncCount++;
    }
  }

  // ===========================================================================
  // Data management
  // ===========================================================================

  Future<void> initializeEmptyData() async {
    items = [];
    customers = [];
    challans = [];

    await saveItems();
    await saveCustomers();
    await saveChallans();
    await saveShop();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyInitialized, true);
  }

  Future<void> clearAllData() async {
    items.clear();
    customers.clear();
    challans.clear();
    await saveItems();
    await saveCustomers();
    await saveChallans();
  }

  /// Next auto-incrementing challan number
  String getNextChallanNumber() {
    int maxNum = 0;
    for (final c in challans) {
      final match = RegExp(r'RK-(\d+)').firstMatch(c.challanNumber);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    return 'RK-${maxNum + 1}';
  }
}
