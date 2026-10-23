class MonthlyRevenuePoint {
  final String month;
  final double amount;
  final String formatted;

  MonthlyRevenuePoint({
    required this.month,
    required this.amount,
    required this.formatted,
  });

  Map<String, dynamic> toMap() => {
    'month': month,
    'amount': amount,
    'formatted': formatted,
  };
}

class DashboardMetrics {
  final int totalItems;
  final int readyToDispatch;
  final int activeChallans;
  final int overdueReturns;
  final double readyPercentage;
  final double currentMonthRevenue;
  final double momGrowthPercentage;
  final double securityDepositsHeld;
  final double outstandingDues;
  final int outstandingClientsCount;
  final List<MonthlyRevenuePoint> revenueTrend;
  final int syncQueueCount;
  final String lastSyncTime;
  final String shopName;
  final String shopCity;
  final String operatorName;

  DashboardMetrics({
    required this.totalItems,
    required this.readyToDispatch,
    required this.activeChallans,
    required this.overdueReturns,
    required this.readyPercentage,
    required this.currentMonthRevenue,
    required this.momGrowthPercentage,
    required this.securityDepositsHeld,
    required this.outstandingDues,
    required this.outstandingClientsCount,
    required this.revenueTrend,
    required this.syncQueueCount,
    required this.lastSyncTime,
    required this.shopName,
    required this.shopCity,
    required this.operatorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalItems': totalItems,
      'readyToDispatch': readyToDispatch,
      'activeChallans': activeChallans,
      'overdueReturns': overdueReturns,
      'readyPercentage': readyPercentage,
      'currency': 'Rs.',
      'currentMonthRevenue': currentMonthRevenue,
      'momGrowthPercentage': momGrowthPercentage,
      'securityDepositsHeld': securityDepositsHeld,
      'outstandingDues': outstandingDues,
      'outstandingClientsCount': outstandingClientsCount,
      'revenueTrend': revenueTrend.map((p) => p.toMap()).toList(),
      'syncQueueCount': syncQueueCount,
      'lastSyncTime': lastSyncTime,
      'shop': {
        'name': shopName,
        'city': shopCity,
        'operator': operatorName,
      },
    };
  }
}
