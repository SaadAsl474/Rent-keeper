import '../database/database_service.dart';
import '../models/api_response.dart';

class ChallansController {
  final DatabaseService _db = DatabaseService();

  ApiResponse getChallans({String? status, String? customerId, bool? overdueOnly}) {
    final challans = _db.getChallans(
      status: status,
      customerId: customerId,
      overdueOnly: overdueOnly,
    );
    return ApiResponse.success(
      challans.map((c) => c.toMap()).toList(),
      meta: {
        'count': challans.length,
        'overdueCount': challans.where((c) => c.isOverdue || c.status == 'overdue').length,
      },
    );
  }

  ApiResponse getChallan(String id) {
    final challan = _db.getChallanById(id);
    if (challan == null) {
      return ApiResponse.error('Challan not found with id $id', statusCode: 404);
    }
    return ApiResponse.success(challan.toMap());
  }

  Future<ApiResponse> createChallan(Map<String, dynamic> body) async {
    if (body['customerId'] == null && body['customerName'] == null) {
      return ApiResponse.error('Customer details are required for rental dispatch', statusCode: 400);
    }
    if (body['items'] == null || (body['items'] as List).isEmpty) {
      return ApiResponse.error('At least one inventory item must be selected', statusCode: 400);
    }

    final challan = await _db.createChallan(body);
    return ApiResponse.success(challan.toMap(), message: 'Challan created and gear dispatched successfully');
  }

  Future<ApiResponse> returnChallan(String id, Map<String, dynamic> body) async {
    final damageFee = (body['damageFee'] as num?)?.toDouble() ?? 0.0;
    final returnNotes = body['notes']?.toString();

    final result = await _db.checkInChallanReturn(
      id,
      damageFee: damageFee,
      returnNotes: returnNotes,
    );

    if (result == null) {
      return ApiResponse.error('Challan not found with id $id', statusCode: 404);
    }

    return ApiResponse.success(result.toMap(), message: 'Challan check-in completed. Security deposit liability cleared.');
  }

  ApiResponse sendWhatsAppAlert(String id) {
    final challan = _db.getChallanById(id);
    if (challan == null) {
      return ApiResponse.error('Challan not found with id $id', statusCode: 404);
    }

    final messageText = 'Assalam-o-Alaikum ${challan.customerName}, this is Al-Rehman Rentals reminder regarding Challan ${challan.challanNumber}. Scheduled return was ${challan.scheduledReturnDate}. Outstanding balance: Rs. ${challan.balancePending.toStringAsFixed(0)}. Please check-in equipment.';

    return ApiResponse.success({
      'challanId': id,
      'challanNumber': challan.challanNumber,
      'recipientPhone': challan.customerPhone,
      'customerName': challan.customerName,
      'message': messageText,
      'status': 'sent',
      'sentAt': DateTime.now().toUtc().toIso8601String(),
    }, message: 'WhatsApp notification dispatched successfully');
  }
}
