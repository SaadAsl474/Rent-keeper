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

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'dailyRate': dailyRate,
        'days': days,
        'totalRent': totalRent,
      };

  factory ChallanItem.fromJson(Map<String, dynamic> json) => ChallanItem(
        itemId: json['itemId'] ?? '',
        itemName: json['itemName'] ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
        days: (json['days'] as num?)?.toInt() ?? 1,
        totalRent: (json['totalRent'] as num?)?.toDouble() ?? 0.0,
      );
}

class Challan {
  final String id;
  String challanNumber;
  String customerId;
  String customerName;
  String customerPhone;
  String customerCnic;
  List<ChallanItem> items;
  DateTime dispatchDate;
  DateTime scheduledReturnDate;
  DateTime? actualReturnDate;
  String status; // 'active', 'overdue', 'completed', 'cancelled'
  double totalAmount;
  double securityDepositHeld;
  double paidAmount;
  double balancePending;
  double lateFee;
  String venue;
  String notes;
  DateTime updatedAt;

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
    this.status = 'active',
    required this.totalAmount,
    this.securityDepositHeld = 0.0,
    this.paidAmount = 0.0,
    this.balancePending = 0.0,
    this.lateFee = 0.0,
    this.venue = '',
    this.notes = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isOverdue {
    if (status == 'completed' || status == 'cancelled') return false;
    return DateTime.now().isAfter(scheduledReturnDate);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'challanNumber': challanNumber,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerCnic': customerCnic,
        'items': items.map((i) => i.toJson()).toList(),
        'dispatchDate': dispatchDate.toIso8601String(),
        'scheduledReturnDate': scheduledReturnDate.toIso8601String(),
        'actualReturnDate': actualReturnDate?.toIso8601String(),
        'status': status,
        'totalAmount': totalAmount,
        'securityDepositHeld': securityDepositHeld,
        'paidAmount': paidAmount,
        'balancePending': balancePending,
        'lateFee': lateFee,
        'venue': venue,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Challan.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<ChallanItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => ChallanItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList();
    }

    return Challan(
      id: json['id'] ?? 'chal_${DateTime.now().millisecondsSinceEpoch}',
      challanNumber: json['challanNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerCnic: json['customerCnic'] ?? '',
      items: parsedItems,
      dispatchDate: json['dispatchDate'] != null
          ? DateTime.tryParse(json['dispatchDate']) ?? DateTime.now()
          : DateTime.now(),
      scheduledReturnDate: json['scheduledReturnDate'] != null
          ? DateTime.tryParse(json['scheduledReturnDate']) ??
              DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      actualReturnDate: json['actualReturnDate'] != null
          ? DateTime.tryParse(json['actualReturnDate'])
          : null,
      status: json['status'] ?? 'active',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      securityDepositHeld:
          (json['securityDepositHeld'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balancePending: (json['balancePending'] as num?)?.toDouble() ?? 0.0,
      lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0.0,
      venue: json['venue'] ?? '',
      notes: json['notes'] ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
