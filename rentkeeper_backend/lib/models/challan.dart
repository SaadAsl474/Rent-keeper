class ChallanItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final double dailyRate;
  final int days;
  final double totalRent;

  ChallanItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.dailyRate,
    required this.days,
    required this.totalRent,
  });

  factory ChallanItem.fromMap(Map<String, dynamic> map) {
    final qty = (map['quantity'] as num?)?.toInt() ?? 1;
    final rate = (map['dailyRate'] as num?)?.toDouble() ?? 0.0;
    final days = (map['days'] as num?)?.toInt() ?? 1;
    final calculatedTotal = qty * rate * days;

    return ChallanItem(
      itemId: map['itemId']?.toString() ?? '',
      itemName: map['itemName']?.toString() ?? '',
      quantity: qty,
      dailyRate: rate,
      days: days,
      totalRent: (map['totalRent'] as num?)?.toDouble() ?? calculatedTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'dailyRate': dailyRate,
      'days': days,
      'totalRent': totalRent,
    };
  }
}

class Challan {
  final String id;
  final String challanNumber; // e.g. "RK-8821"
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerCnic;
  final List<ChallanItem> items;
  final String dispatchDate;
  final String scheduledReturnDate;
  final String? actualReturnDate;
  final String status; // 'booked', 'dispatched', 'completed', 'overdue', 'cancelled'
  final double totalAmount;
  final double securityDepositHeld; // Collateral liability, non-revenue
  final double paidAmount;
  final double balancePending;
  final double lateFee;
  final String venue;
  final String notes;
  final String updatedAt;

  Challan({
    required this.id,
    required this.challanNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerCnic,
    required this.items,
    required this.dispatchDate,
    required this.scheduledReturnDate,
    this.actualReturnDate,
    required this.status,
    required this.totalAmount,
    required this.securityDepositHeld,
    required this.paidAmount,
    required this.balancePending,
    this.lateFee = 0.0,
    this.venue = '',
    this.notes = '',
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc().toIso8601String();

  bool get isOverdue {
    if (status == 'completed' || actualReturnDate != null) return false;
    final scheduled = DateTime.tryParse(scheduledReturnDate);
    if (scheduled == null) return false;
    return DateTime.now().isAfter(scheduled);
  }

  factory Challan.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .map((item) => ChallanItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return Challan(
      id: map['id']?.toString() ?? '',
      challanNumber: map['challanNumber']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      customerCnic: map['customerCnic']?.toString() ?? '',
      items: parsedItems,
      dispatchDate: map['dispatchDate']?.toString() ?? DateTime.now().toIso8601String(),
      scheduledReturnDate: map['scheduledReturnDate']?.toString() ?? DateTime.now().toIso8601String(),
      actualReturnDate: map['actualReturnDate']?.toString(),
      status: map['status']?.toString() ?? 'dispatched',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      securityDepositHeld: (map['securityDepositHeld'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balancePending: (map['balancePending'] as num?)?.toDouble() ?? 0.0,
      lateFee: (map['lateFee'] as num?)?.toDouble() ?? 0.0,
      venue: map['venue']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challanNumber': challanNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerCnic': customerCnic,
      'items': items.map((i) => i.toMap()).toList(),
      'dispatchDate': dispatchDate,
      'scheduledReturnDate': scheduledReturnDate,
      if (actualReturnDate != null) 'actualReturnDate': actualReturnDate,
      'status': status,
      'totalAmount': totalAmount,
      'securityDepositHeld': securityDepositHeld,
      'paidAmount': paidAmount,
      'balancePending': balancePending,
      'lateFee': lateFee,
      'venue': venue,
      'notes': notes,
      'isOverdue': isOverdue,
      'updatedAt': updatedAt,
    };
  }

  Challan copyWith({
    String? status,
    String? actualReturnDate,
    double? totalAmount,
    double? securityDepositHeld,
    double? paidAmount,
    double? balancePending,
    double? lateFee,
    String? venue,
    String? notes,
  }) {
    return Challan(
      id: id,
      challanNumber: challanNumber,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerCnic: customerCnic,
      items: items,
      dispatchDate: dispatchDate,
      scheduledReturnDate: scheduledReturnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      securityDepositHeld: securityDepositHeld ?? this.securityDepositHeld,
      paidAmount: paidAmount ?? this.paidAmount,
      balancePending: balancePending ?? this.balancePending,
      lateFee: lateFee ?? this.lateFee,
      venue: venue ?? this.venue,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}
