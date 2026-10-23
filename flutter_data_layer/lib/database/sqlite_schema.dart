/// RentKeeper Local SQLite Database Schema
/// Compatible with Flutter `sqflite` and `sqlite3` packages.
class SqliteSchema {
  static const String databaseName = 'rentkeeper_local.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String tableItems = 'items';
  static const String tableCustomers = 'customers';
  static const String tableChallans = 'challans';
  static const String tableSyncQueue = 'sync_queue';

  // SQL Table Definitions
  static const String createItemsTable = '''
    CREATE TABLE IF NOT EXISTS $tableItems (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      barcode TEXT,
      serialNumber TEXT,
      dailyRate REAL NOT NULL,
      replacementValue REAL NOT NULL,
      totalStock INTEGER NOT NULL,
      availableStock INTEGER NOT NULL,
      rentedStock INTEGER NOT NULL,
      condition TEXT NOT NULL,
      status TEXT NOT NULL,
      description TEXT,
      imageUrl TEXT,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String createCustomersTable = '''
    CREATE TABLE IF NOT EXISTS $tableCustomers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      cnic TEXT NOT NULL,
      address TEXT,
      outstandingBalance REAL NOT NULL DEFAULT 0.0,
      activeRentalsCount INTEGER NOT NULL DEFAULT 0,
      totalBookings INTEGER NOT NULL DEFAULT 0,
      isVerified INTEGER NOT NULL DEFAULT 1,
      notes TEXT,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String createChallansTable = '''
    CREATE TABLE IF NOT EXISTS $tableChallans (
      id TEXT PRIMARY KEY,
      challanNumber TEXT NOT NULL UNIQUE,
      customerId TEXT NOT NULL,
      customerName TEXT NOT NULL,
      customerPhone TEXT NOT NULL,
      customerCnic TEXT NOT NULL,
      itemsJson TEXT NOT NULL,
      dispatchDate TEXT NOT NULL,
      scheduledReturnDate TEXT NOT NULL,
      actualReturnDate TEXT,
      status TEXT NOT NULL,
      totalAmount REAL NOT NULL,
      securityDepositHeld REAL NOT NULL,
      paidAmount REAL NOT NULL,
      balancePending REAL NOT NULL,
      lateFee REAL NOT NULL DEFAULT 0.0,
      venue TEXT,
      notes TEXT,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String createSyncQueueTable = '''
    CREATE TABLE IF NOT EXISTS $tableSyncQueue (
      mutationId TEXT PRIMARY KEY,
      entityType TEXT NOT NULL,
      action TEXT NOT NULL,
      entityId TEXT NOT NULL,
      payloadJson TEXT NOT NULL,
      clientTimestamp TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      retryCount INTEGER NOT NULL DEFAULT 0
    );
  ''';
}
