import '../database/database_service.dart';
import '../models/api_response.dart';

class ShopController {
  final DatabaseService _db = DatabaseService();

  ApiResponse getProfile() {
    final profile = _db.getShopProfile();
    return ApiResponse.success(profile);
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> body) async {
    final updated = await _db.updateShopProfile(body);
    return ApiResponse.success(updated, message: 'Shop profile updated successfully');
  }
}
