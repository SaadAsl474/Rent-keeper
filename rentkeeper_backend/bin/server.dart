import 'dart:io';
import '../lib/config/app_config.dart';
import '../lib/database/database_service.dart';
import '../lib/middleware/cors_middleware.dart';
import '../lib/middleware/logger_middleware.dart';
import '../lib/routes/router.dart';

Future<void> main(List<String> args) async {
  print('================================================================');
  print('       RENTKEEPER OPERATIONAL PRECISION - DART BACKEND          ');
  print('               Commercial Rental & Dispatch Server              ');
  print('================================================================');

  // Parse command line arguments
  var host = AppConfig.host;
  var port = AppConfig.port;

  for (var arg in args) {
    if (arg.startsWith('--port=')) {
      port = int.tryParse(arg.split('=')[1]) ?? port;
    } else if (arg.startsWith('--host=')) {
      host = arg.split('=')[1];
    }
  }

  // 1. Initialize persistent storage engine & seeds
  print('[1/2] Initializing storage engine...');
  final db = DatabaseService();
  await db.init();

  // 2. Start HTTP Server
  print('[2/2] Starting HTTP REST API Server on $host:$port...');
  final router = ApiRouter();

  final server = await HttpServer.bind(
    host == '0.0.0.0' ? InternetAddress.anyIPv4 : host,
    port,
    shared: true,
  );

  final shop = db.getShopProfile();
  print('----------------------------------------------------------------');
  print('Server online at: http://${server.address.host == "0.0.0.0" ? "localhost" : server.address.host}:${server.port}');
  print('Store:            ${shop["name"]} (${shop["city"]})');
  print('Active Currency:  ${AppConfig.currency} (PKR)');
  print('Offline Mode:     ${shop["syncStatus"]}');
  print('----------------------------------------------------------------');
  print('Key Endpoints:');
  print('  • Pulse Dashboard:   GET  http://localhost:$port/api/v1/dashboard');
  print('  • Inventory Items:   GET  http://localhost:$port/api/v1/items');
  print('  • Rental Challans:   GET  http://localhost:$port/api/v1/challans');
  print('  • Overdue Returns:   GET  http://localhost:$port/api/v1/challans?overdue=true');
  print('  • Customers:         GET  http://localhost:$port/api/v1/customers');
  print('  • Revenue Trends:    GET  http://localhost:$port/api/v1/dashboard/revenue-trend');
  print('  • SQLite Sync Push:  POST http://localhost:$port/api/v1/sync/push');
  print('  • SQLite Sync Pull:  GET  http://localhost:$port/api/v1/sync/pull');
  print('================================================================');
  print('Listening for incoming requests... (Press Ctrl+C to stop)\n');

  // Request loop
  await for (HttpRequest request in server) {
    final stopwatch = Stopwatch()..start();

    // Apply CORS headers immediately
    CorsMiddleware.apply(request);

    // Handle preflight OPTIONS
    if (CorsMiddleware.handlePreflight(request)) {
      stopwatch.stop();
      LoggerMiddleware.logRequest(request, request.response.statusCode, stopwatch.elapsedMilliseconds);
      continue;
    }

    // Route request
    try {
      await router.handle(request);
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"success":false,"error":"$e"}');
      await request.response.close();
    } finally {
      stopwatch.stop();
      LoggerMiddleware.logRequest(request, request.response.statusCode, stopwatch.elapsedMilliseconds);
    }
  }
}
