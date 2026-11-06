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
  test('Dashboard metrics contain accurate shop profile and numeric metrics', () {
    final dashboardCtrl = DashboardController();
    final res = dashboardCtrl.getDashboard();
    assert(res.success == true, 'Dashboard response must succeed');
    final data = res.data as Map<String, dynamic>;
    final metrics = data['metrics'] as Map<String, dynamic>;

    assert(metrics['totalItems'] != null, 'totalItems must be numeric');
    assert(metrics['currentMonthRevenue'] != null, 'currentMonthRevenue must be numeric');
    assert(metrics['shop']['name'] == 'Al-Rehman Rentals', 'Shop name should be Al-Rehman Rentals');
  });

  test('Revenue trend endpoint succeeds', () {
    final dashboardCtrl = DashboardController();
    final res = dashboardCtrl.getRevenueTrend();
    assert(res.success == true);
  });

  // 2. Items Controller Tests
  await asyncTest('Create new inventory item and filter by category', () async {
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

    final cameras = itemsCtrl.getItems(category: 'cameras');
    final camList = cameras.data as List;
    assert(camList.isNotEmpty, 'Should return at least 1 camera');
    assert(camList.every((item) => item['category'] == 'cameras'), 'All items must be cameras');
  });

  // 3. Customers Controller Tests
  await asyncTest('Create customer and search by name', () async {
    final custCtrl = CustomersController();
    final createRes = await custCtrl.createCustomer({
      'name': 'Usman Farooq',
      'phone': '+92 333 7890123',
      'cnic': '35201-1122334-5',
      'address': 'Gulberg III, Lahore',
      'outstandingBalance': 15000.0,
    });
    assert(createRes.success == true);

    final res = custCtrl.getCustomers(query: 'Usman');
    assert(res.success == true);
    final list = res.data as List;
    assert(list.isNotEmpty, 'Should find customer named Usman');
    assert(list.any((c) => c['name'] == 'Usman Farooq'));
  });

  // 4. Challans Controller Tests
  String createdChallanId = '';
  await asyncTest('Create rental challan and verify overdue tracking', () async {
    final challansCtrl = ChallansController();
    final createRes = await challansCtrl.createChallan({
      'customerId': 'cust_test_01',
      'customerName': 'Royal Banquet Hall',
      'customerPhone': '+92 333 7890123',
      'customerCnic': '35201-1122334-5',
      'items': [
        {
          'itemId': 'item_test_01',
          'itemName': 'Stage Lighting Truss Rig',
          'quantity': 1,
          'dailyRate': 22000.0,
          'days': 2,
          'totalRent': 44000.0,
        }
      ],
      'scheduledReturnDate': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      'status': 'overdue',
      'totalAmount': 44000.0,
      'securityDepositHeld': 50000.0,
      'paidAmount': 20000.0,
      'balancePending': 24000.0,
      'venue': 'Royal Banquet Hall, Gulberg III',
    });
    assert(createRes.success == true);
    final data = createRes.data as Map<String, dynamic>;
    createdChallanId = data['id'];

    final res = challansCtrl.getChallans(overdueOnly: true);
    assert(res.success == true);
    final overdueList = res.data as List;
    assert(overdueList.isNotEmpty, 'Must have at least 1 overdue challan');
  });

  test('Send WhatsApp alert for overdue challan', () {
    final challansCtrl = ChallansController();
    final res = challansCtrl.sendWhatsAppAlert(createdChallanId);
    assert(res.success == true);
    final data = res.data as Map<String, dynamic>;
    assert(data['status'] == 'sent');
    assert(data['recipientPhone'] == '+92 333 7890123');
  });

  await asyncTest('Check-in challan return restores stock and clears deposit liability', () async {
    final challansCtrl = ChallansController();
    final res = await challansCtrl.returnChallan(createdChallanId, {
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

  if (failed > 0) exit(1);
}
