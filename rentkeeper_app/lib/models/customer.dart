class Customer {
  final String id;
  String name;
  String phone;
  String cnic;
  String address;
  double outstandingBalance;
  int activeRentalsCount;
  int totalBookings;
  bool isVerified;
  String notes;
  DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.cnic,
    this.address = '',
    this.outstandingBalance = 0.0,
    this.activeRentalsCount = 0,
    this.totalBookings = 0,
    this.isVerified = true,
    this.notes = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'cnic': cnic,
        'address': address,
        'outstandingBalance': outstandingBalance,
        'activeRentalsCount': activeRentalsCount,
        'totalBookings': totalBookings,
        'isVerified': isVerified ? 1 : 0,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 'cust_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      cnic: json['cnic'] ?? '',
      address: json['address'] ?? '',
      outstandingBalance: (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      activeRentalsCount: (json['activeRentalsCount'] as num?)?.toInt() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] == 1 || json['isVerified'] == true,
      notes: json['notes'] ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
