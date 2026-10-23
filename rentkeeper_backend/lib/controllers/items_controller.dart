import '../database/database_service.dart';
import '../models/api_response.dart';

class ItemsController {
  final DatabaseService _db = DatabaseService();

  ApiResponse getItems({String? category, String? status, String? query}) {
    final items = _db.getItems(category: category, status: status, query: query);
    return ApiResponse.success(
      items.map((i) => i.toMap()).toList(),
      meta: {
        'count': items.length,
        'filters': {
          'category': category ?? 'all',
          'status': status ?? 'all',
          'query': query ?? '',
        },
      },
    );
  }

  ApiResponse getItem(String id) {
    final item = _db.getItemById(id);
    if (item == null) {
      return ApiResponse.error('Item not found with id $id', statusCode: 404);
    }
    return ApiResponse.success(item.toMap());
  }

  Future<ApiResponse> createItem(Map<String, dynamic> body) async {
    if (body['name'] == null || body['name'].toString().trim().isEmpty) {
      return ApiResponse.error('Item name is required', statusCode: 400);
    }
    if (body['dailyRate'] == null) {
      return ApiResponse.error('dailyRate (Rs.) is required', statusCode: 400);
    }

    final item = await _db.createItem(body);
    return ApiResponse.success(item.toMap(), message: 'Inventory item created successfully');
  }

  Future<ApiResponse> updateItem(String id, Map<String, dynamic> body) async {
    final updated = await _db.updateItem(id, body);
    if (updated == null) {
      return ApiResponse.error('Item not found with id $id', statusCode: 404);
    }
    return ApiResponse.success(updated.toMap(), message: 'Inventory item updated successfully');
  }

  Future<ApiResponse> deleteItem(String id) async {
    final success = await _db.deleteItem(id);
    if (!success) {
      return ApiResponse.error('Item not found with id $id', statusCode: 404);
    }
    return ApiResponse.success({'deletedId': id}, message: 'Item deleted from inventory');
  }
}
