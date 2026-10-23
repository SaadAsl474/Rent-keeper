import 'dart:io';
import '../lib/config/app_config.dart';
import '../lib/database/database_service.dart';
import '../lib/controllers/dashboard_controller.dart';
import '../lib/controllers/items_controller.dart';
import '../lib/controllers/challans_controller.dart';
import '../lib/controllers/customers_controller.dart';
import '../lib/controllers/sync_controller.dart';

void main() async {
  print('--- RUNNING RENTKEEPER DART BACKEND UNIT & INTEGRATION TESTS ---');

  // Test with temporary in-memory / scratch DB file
  final tempDb = File('data/test_rentkeeper_db.json');
  if (tempDb.existsSync()) tempDb.deleteSync();

  final db = DatabaseService();
  await db.init();

  int passed = 0;
  int failed = 0;

  void test(String name, void Function() body) {
    try {
      body();
      print(' [PASS] $name');
      passed++;
    } catch (e, stack) {
      print(' [FAIL] $name: $e');
      print(stack);
      failed++;
    }
  }

  Future<void> asyncTest(String name, Future<void> Function() body) async {
    try {
      await body();
      print(' [PASS] $name');
      passed++;
    } catch (e, stack) {
      print(' [FAIL] $name: $e');
      print(stack);
      failed++;
    }
  }

  // 1. Dashboard Controller Tests
  test('Dashboard metrics contain accurate RentKeeper figures', () {
    final dashboardCtrl = DashboardController();
    final res = dashboardCtrl.getDashboard();
    assert(res.success == true, 'Dashboard response must succeed');
    final data = res.data as Map<String, dynamic>;
    final metrics = data['metrics'] as Map<String, dynamic>;

    assert(metrics['totalItems'] == 142, 'Expected 142 total items');
    assert(metrics['currentMonthRevenue'] == 485000.0, 'Expected Rs. 485,000 revenue');
    assert(metrics['securityDepositsHeld'] > 0, 'Security deposits held should be greater than 0');
    assert(metrics['shop']['name'] == 'Al-Rehman Rentals', 'Shop name should be Al-Rehman Rentals');
  });

  test('Revenue trend contains 6-month historical figures', () {
    final dashboardCtrl = DashboardController();
    final res = dashboardCtrl.getRevenueTrend();
    assert(res.success == true);
    final data = res.data as Map<String, dynamic>;
    final trend = data['trend'] as List;
    assert(trend.length == 6, 'Must contain 6 monthly points');
    assert(data['momGrowthPercentage'] == 18.4, 'Expected +18.4% MoM growth');
  });

  // 2. Items Controller Tests
  test('Items controller lists inventory and filters by category', () {
    final itemsCtrl = ItemsController();
    final all = itemsCtrl.getItems();
    assert(all.success == true);
    final list = all.data as List;
    assert(list.isNotEmpty, 'Should return listed items');

    final cameras = itemsCtrl.getItems(category: 'cameras');
    final camList = cameras.data as List;
    assert(camList.every((item) => item['category'] == 'cameras'), 'All items must be cameras');
  });

  await asyncTest('Create new inventory item', () async {
    final itemsCtrl = ItemsController();
    final res = await itemsCtrl.createItem({
      'name': 'Blackmagic Pocket Cinema 6K Pro',
      'category': 'cameras',
      'barcode': 'BC-BMPCC-6K',
      'serialNumber': 'SN-BMD-9982',
      'dailyRate': 18000.0,
      'replacementValue': 750000.0,
      'totalStock': 3,
      'availableStock': 3,
      'rentedStock': 0,
      'condition': 'mint',
      'status': 'available',
      'description': '6K Super 35 HDR sensor cinema camera.',
    });
    assert(res.success == true);
    final created = res.data as Map<String, dynamic>;
    assert(created['name'] == 'Blackmagic Pocket Cinema 6K Pro');
  });

  // 3. Customers Controller Tests
  test('Customers listing and search by name/CNIC', () {
    final custCtrl = CustomersController();
    final res = custCtrl.getCustomers(query: 'Usman');
    assert(res.success == true);
    final list = res.data as List;
    assert(list.length == 1, 'Should find 1 customer named Usman');
    assert(list.first['name'] == 'Usman Farooq');
    assert(list.first['outstandingBalance'] == 15000.0);
  });

  // 4. Challans Controller Tests
  test('Challans list includes overdue alert for Challan #RK-8821', () {
    final challansCtrl = ChallansController();
    final res = challansCtrl.getChallans(overdueOnly: true);
    assert(res.success == true);
    final overdueList = res.data as List;
    assert(overdueList.isNotEmpty, 'Must have overdue challans');
    final firstOverdue = overdueList.first;
    assert(firstOverdue['challanNumber'] == 'RK-8821');
  });

  test('Send WhatsApp alert for overdue challan', () {
    final challansCtrl = ChallansController();
    final res = challansCtrl.sendWhatsAppAlert('chal_8821');
    assert(res.success == true);
    final data = res.data as Map<String, dynamic>;
    assert(data['status'] == 'sent');
    assert(data['recipientPhone'] == '+92 333 7890123');
  });

  await asyncTest('Check-in challan return restores stock and clears deposit liability', () async {
    final challansCtrl = ChallansController();
    final res = await challansCtrl.returnChallan('chal_8820', {
      'notes': 'Returned on time, no damages found.',
    });
    assert(res.success == true);
    final updated = res.data as Map<String, dynamic>;
    assert(updated['status'] == 'completed');
    assert(updated['securityDepositHeld'] == 0.0);
  });

  // 5. Offline Sync Tests
  await asyncTest('Offline sync push and pull handshake', () async {
    final syncCtrl = SyncController();
    final pushRes = await syncCtrl.pushMutations({
      'mutations': [
        {
          'mutationId': 'mut_1001',
          'entityType': 'customer',
          'action': 'create',
          'entityId': 'cust_new_offline',
          'payload': {
            'id': 'cust_new_offline',
            'name': 'Hamza Sheikh',
            'phone': '+92 300 9988776',
            'cnic': '35201-1122998-7',
            'address': 'Model Town, Lahore',
            'outstandingBalance': 0.0,
            'activeRentalsCount': 0,
            'totalBookings': 1,
          },
          'clientTimestamp': DateTime.now().toIso8601String(),
        }
      ]
    });
    assert(pushRes.success == true);
    final pushData = pushRes.data as Map<String, dynamic>;
    assert(pushData['processed'] == 1);

    final pullRes = syncCtrl.pullChanges();
    assert(pullRes.success == true);
    final pullData = pullRes.data as Map<String, dynamic>;
    final pulledCustomers = pullData['customers'] as List;
    assert(pulledCustomers.any((c) => c['name'] == 'Hamza Sheikh'));
  });

  print('\n----------------------------------------------------------------');
  print('TEST SUMMARY: $passed Passed, $failed Failed');
  print('----------------------------------------------------------------\n');

  if (failed > 0) {
    exit(1);
  }
}
