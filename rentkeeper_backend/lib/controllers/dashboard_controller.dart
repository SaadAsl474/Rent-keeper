import '../database/database_service.dart';
import '../models/api_response.dart';

class DashboardController {
  final DatabaseService _db = DatabaseService();

  ApiResponse getDashboard() {
    final metrics = _db.getDashboardMetrics();
    final upcomingOrOverdueChallans = _db.getChallans(overdueOnly: false).take(5).map((c) => c.toMap()).toList();

    return ApiResponse.success({
      'metrics': metrics.toMap(),
      'upcomingSchedule': upcomingOrOverdueChallans,
      'offlineSync': {
        'status': 'SQLite Ready',
        'isOnline': true,
        'pendingQueue': metrics.syncQueueCount,
        'lastSync': metrics.lastSyncTime,
      },
    }, message: 'RentKeeper dashboard pulse retrieved');
  }

  ApiResponse getRevenueTrend() {
    final metrics = _db.getDashboardMetrics();
    return ApiResponse.success({
      'currency': 'Rs.',
      'currentMonthRevenue': metrics.currentMonthRevenue,
      'momGrowthPercentage': metrics.momGrowthPercentage,
      'trend': metrics.revenueTrend.map((t) => t.toMap()).toList(),
      'securityDepositsHeld': metrics.securityDepositsHeld,
      'outstandingDues': metrics.outstandingDues,
    }, message: 'Financial ledger trend retrieved');
  }
}
