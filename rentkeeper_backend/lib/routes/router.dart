import 'dart:convert';
import 'dart:io';
import '../config/app_config.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/items_controller.dart';
import '../controllers/challans_controller.dart';
import '../controllers/customers_controller.dart';
import '../controllers/sync_controller.dart';
import '../controllers/shop_controller.dart';
import '../models/api_response.dart';

class ApiRouter {
  final DashboardController _dashboardCtrl = DashboardController();
  final ItemsController _itemsCtrl = ItemsController();
  final ChallansController _challansCtrl = ChallansController();
  final CustomersController _customersCtrl = CustomersController();
  final SyncController _syncCtrl = SyncController();
  final ShopController _shopCtrl = ShopController();

  Future<void> handle(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;
    final queryParams = request.uri.queryParameters;

    ApiResponse response;
    int statusCode = HttpStatus.ok;

    try {
      // 1. Root, UI Web App, and Meta Endpoints
      final acceptsHtml = request.headers.value('accept')?.contains('text/html') ?? false;
      if ((path == '/' || path == '/app') && (acceptsHtml || path == '/app')) {
        final possiblePaths = ['code.html', '../code.html', 'stitch_rentkeeper_flutter_ui_design/code.html'];
        File? htmlFile;
        for (var p in possiblePaths) {
          final f = File(p);
          if (f.existsSync()) {
            htmlFile = f;
            break;
          }
        }

        if (htmlFile != null) {
          final htmlContent = await htmlFile.readAsString();
          final res = request.response;
          res.statusCode = HttpStatus.ok;
          res.headers.set('Content-Type', 'text/html; charset=utf-8');
          res.write(htmlContent);
          await res.close();
          return;
        }
      }

      if (path == '/' || path == '/api' || path == '/api/v1') {
        response = ApiResponse.success({
          'app': AppConfig.appName,
          'version': AppConfig.appVersion,
          'environment': AppConfig.environment,
          'currency': AppConfig.currency,
          'documentation': {
            'dashboard': 'GET /api/v1/dashboard',
            'revenueTrend': 'GET /api/v1/dashboard/revenue-trend',
            'items': 'GET, POST /api/v1/items',
            'itemDetails': 'GET, PUT, DELETE /api/v1/items/:id',
            'challans': 'GET, POST /api/v1/challans',
            'challanReturn': 'POST /api/v1/challans/:id/return',
            'whatsappAlert': 'POST /api/v1/challans/:id/whatsapp-alert',
            'customers': 'GET, POST /api/v1/customers',
            'customerDetails': 'GET, PUT /api/v1/customers/:id',
            'syncPush': 'POST /api/v1/sync/push',
            'syncPull': 'GET /api/v1/sync/pull',
            'syncStatus': 'GET /api/v1/sync/status',
            'shopProfile': 'GET, PUT /api/v1/shop',
          },
        }, message: 'RentKeeper Operational Precision Backend is running smoothly');
      }

      // 2. DASHBOARD
      else if (path == '/api/v1/dashboard' && method == 'GET') {
        response = _dashboardCtrl.getDashboard();
      } else if (path == '/api/v1/dashboard/revenue-trend' && method == 'GET') {
        response = _dashboardCtrl.getRevenueTrend();
      }

      // 3. ITEMS (INVENTORY)
      else if (path == '/api/v1/items') {
        if (method == 'GET') {
          response = _itemsCtrl.getItems(
            category: queryParams['category'],
            status: queryParams['status'],
            query: queryParams['query'],
          );
        } else if (method == 'POST') {
          final body = await _readJsonBody(request);
          response = await _itemsCtrl.createItem(body);
          if (!response.success) statusCode = HttpStatus.badRequest;
        } else {
          response = ApiResponse.error('Method not allowed', statusCode: HttpStatus.methodNotAllowed);
          statusCode = HttpStatus.methodNotAllowed;
        }
      } else if (path.startsWith('/api/v1/items/')) {
        final id = path.replaceFirst('/api/v1/items/', '').trim();
        if (id.isEmpty) {
          response = ApiResponse.error('Item ID missing', statusCode: HttpStatus.badRequest);
          statusCode = HttpStatus.badRequest;
        } else if (method == 'GET') {
          response = _itemsCtrl.getItem(id);
          if (!response.success) statusCode = HttpStatus.notFound;
        } else if (method == 'PUT') {
          final body = await _readJsonBody(request);
          response = await _itemsCtrl.updateItem(id, body);
          if (!response.success) statusCode = HttpStatus.notFound;
        } else if (method == 'DELETE') {
          response = await _itemsCtrl.deleteItem(id);
          if (!response.success) statusCode = HttpStatus.notFound;
        } else {
          response = ApiResponse.error('Method not allowed', statusCode: HttpStatus.methodNotAllowed);
          statusCode = HttpStatus.methodNotAllowed;
        }
      }

      // 4. CHALLANS (RENTAL BOOKINGS & DISPATCHES)
      else if (path == '/api/v1/challans') {
        if (method == 'GET') {
          final overdueOnly = queryParams['overdue'] == 'true';
          response = _challansCtrl.getChallans(
            status: queryParams['status'],
            customerId: queryParams['customerId'],
            overdueOnly: overdueOnly,
          );
        } else if (method == 'POST') {
          final body = await _readJsonBody(request);
          response = await _challansCtrl.createChallan(body);
          if (!response.success) statusCode = HttpStatus.badRequest;
        } else {
          response = ApiResponse.error('Method not allowed', statusCode: HttpStatus.methodNotAllowed);
          statusCode = HttpStatus.methodNotAllowed;
        }
      } else if (path.startsWith('/api/v1/challans/')) {
        final subPath = path.replaceFirst('/api/v1/challans/', '');
        if (subPath.endsWith('/return') && method == 'POST') {
          final id = subPath.replaceAll('/return', '').trim();
          final body = await _readJsonBody(request);
          response = await _challansCtrl.returnChallan(id, body);
          if (!response.success) statusCode = HttpStatus.notFound;
        } else if (subPath.endsWith('/whatsapp-alert') && method == 'POST') {
          final id = subPath.replaceAll('/whatsapp-alert', '').trim();
          response = _challansCtrl.sendWhatsAppAlert(id);
          if (!response.success) statusCode = HttpStatus.notFound;
        } else if (!subPath.contains('/')) {
          final id = subPath.trim();
          if (method == 'GET') {
            response = _challansCtrl.getChallan(id);
            if (!response.success) statusCode = HttpStatus.notFound;
          } else {
            response = ApiResponse.error('Method not allowed', statusCode: HttpStatus.methodNotAllowed);
            statusCode = HttpStatus.methodNotAllowed;
          }
        } else {
          response = ApiResponse.error('Endpoint not found', statusCode: HttpStatus.notFound);
          statusCode = HttpStatus.notFound;
        }
      }

      // 5. CUSTOMERS
      else if (path == '/api/v1/customers') {
        if (method == 'GET') {
          response = _customersCtrl.getCustomers(query: queryParams['query']);
        } else if (method == 'POST') {
          final body = await _readJsonBody(request);
          response = await _customersCtrl.createCustomer(body);
          if (!response.success) statusCode = HttpStatus.badRequest;
        } else {
          response = ApiResponse.error('Method not allowed', statusCode: HttpStatus.methodNotAllowed);
          statusCode = HttpStatus.methodNotAllowed;
        }
      } else if (path.startsWith('/api/v1/customers/')) {
        final id = path.replaceFirst('/api/v1/customers/', '').trim();
        if (method == 'GET') {
          response = _customersCtrl.getCustomer(id);
          if (!response.success) statusCode = HttpStatus.notFound;
        } else if (method == 'PUT') {
          final body = await _readJsonBody(request);
          response = await _customersCtrl.updateCustomer(id, body);
          if (!response.success) statusCode = HttpStatus.notFound;
        } else {
          response = ApiResponse.error('Method not allowed', statusCode: HttpStatus.methodNotAllowed);
          statusCode = HttpStatus.methodNotAllowed;
        }
      }

      // 6. OFFLINE SYNC
      else if (path == '/api/v1/sync/push' && method == 'POST') {
        final body = await _readJsonBody(request);
        response = await _syncCtrl.pushMutations(body);
      } else if (path == '/api/v1/sync/pull' && method == 'GET') {
        response = _syncCtrl.pullChanges(since: queryParams['since']);
      } else if (path == '/api/v1/sync/status' && method == 'GET') {
        response = _syncCtrl.getStatus();
      }

      // 7. SHOP PROFILE
      else if (path == '/api/v1/shop') {
        if (method == 'GET') {
          response = _shopCtrl.getProfile();
        } else if (method == 'PUT') {
          final body = await _readJsonBody(request);
          response = await _shopCtrl.updateProfile(body);
        } else {
          response = ApiResponse.error('Method not allowed', statusCode: HttpStatus.methodNotAllowed);
          statusCode = HttpStatus.methodNotAllowed;
        }
      }

      // 8. NOT FOUND
      else {
        response = ApiResponse.error('Route not found: $method $path', statusCode: HttpStatus.notFound);
        statusCode = HttpStatus.notFound;
      }
    } catch (err, stack) {
      print('[Router Error] $err\n$stack');
      response = ApiResponse.error('Internal Server Error: $err', statusCode: HttpStatus.internalServerError);
      statusCode = HttpStatus.internalServerError;
    }

    _sendJsonResponse(request, response, statusCode);
  }

  Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
    try {
      final content = await utf8.decoder.bind(request).join();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  void _sendJsonResponse(HttpRequest request, ApiResponse response, int statusCode) {
    final res = request.response;
    res.statusCode = statusCode;
    res.headers.contentType = ContentType.json;
    res.write(response.toJson());
    res.close();
  }
}
