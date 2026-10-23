import 'dart:io';

class AppConfig {
  static final String host = Platform.environment['HOST'] ?? '0.0.0.0';
  static final int port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  static final String environment = Platform.environment['APP_ENV'] ?? 'development';

  static const String appName = 'RentKeeper Operational Precision';
  static const String appVersion = '1.0.0';
  static const String currency = 'Rs.';
  static const String defaultCity = 'Lahore';

  // Persistence file location
  static String get databasePath {
    final customPath = Platform.environment['DB_PATH'];
    if (customPath != null && customPath.isNotEmpty) return customPath;
    final dataDir = Directory('data');
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }
    return 'data/rentkeeper_db.json';
  }
}
