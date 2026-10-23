import '../database/database_service.dart';
import '../models/api_response.dart';
import '../models/sync_item.dart';

class SyncController {
  final DatabaseService _db = DatabaseService();

  Future<ApiResponse> pushMutations(Map<String, dynamic> body) async {
    final rawMutations = body['mutations'] as List<dynamic>? ?? [];
    if (rawMutations.isEmpty) {
      return ApiResponse.success({
        'processed': 0,
        'acceptedIds': [],
        'rejected': [],
        'serverTimestamp': DateTime.now().toUtc().toIso8601String(),
      }, message: 'Empty sync queue payload');
    }

    final mutations = rawMutations
        .map((m) => SyncMutation.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();

    final result = await _db.processSyncMutations(mutations);
    return ApiResponse.success(result, message: 'Sync batch processed successfully');
  }

  ApiResponse pullChanges({String? since}) {
    final changes = _db.pullChangesSince(since);
    return ApiResponse.success(changes, message: 'Delta changes pulled successfully');
  }

  ApiResponse getStatus() {
    final shop = _db.getShopProfile();
    return ApiResponse.success({
      'mode': 'SQLite Ready • Synced',
      'isOnline': true,
      'serverTime': DateTime.now().toUtc().toIso8601String(),
      'shop': shop['name'],
      'city': shop['city'],
      'pendingQueue': shop['syncQueueCount'] ?? 0,
    });
  }
}
