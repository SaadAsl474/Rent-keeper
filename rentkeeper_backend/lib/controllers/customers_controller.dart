import '../database/database_service.dart';
import '../models/api_response.dart';

class CustomersController {
  final DatabaseService _db = DatabaseService();

  ApiResponse getCustomers({String? query}) {
    final customers = _db.getCustomers(query: query);
    return ApiResponse.success(
      customers.map((c) => c.toMap()).toList(),
      meta: {
        'count': customers.length,
        'query': query ?? '',
        'totalOutstanding': customers.fold<double>(0.0, (acc, c) => acc + c.outstandingBalance),
      },
    );
  }

  ApiResponse getCustomer(String id) {
    final customer = _db.getCustomerById(id);
    if (customer == null) {
      return ApiResponse.error('Customer not found with id $id', statusCode: 404);
    }
    final challans = _db.getChallans(customerId: id).map((c) => c.toMap()).toList();

    return ApiResponse.success({
      'customer': customer.toMap(),
      'challans': challans,
    });
  }

  Future<ApiResponse> createCustomer(Map<String, dynamic> body) async {
    if (body['name'] == null || body['name'].toString().trim().isEmpty) {
      return ApiResponse.error('Customer name is required', statusCode: 400);
    }
    if (body['phone'] == null || body['phone'].toString().trim().isEmpty) {
      return ApiResponse.error('Customer phone number is required', statusCode: 400);
    }

    final customer = await _db.createCustomer(body);
    return ApiResponse.success(customer.toMap(), message: 'Customer registered successfully');
  }

  Future<ApiResponse> updateCustomer(String id, Map<String, dynamic> body) async {
    final updated = await _db.updateCustomer(id, body);
    if (updated == null) {
      return ApiResponse.error('Customer not found with id $id', statusCode: 404);
    }
    return ApiResponse.success(updated.toMap(), message: 'Customer updated successfully');
  }
}
