class Customer {
  final String id;
  final String name;
  final String phone;
  final String cnic;
  final String address;
  final double outstandingBalance;
  final int activeRentalsCount;
  final int totalBookings;
  final bool isVerified;
  final String notes;
  final String updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.cnic,
    required this.address,
    required this.outstandingBalance,
    required this.activeRentalsCount,
    required this.totalBookings,
    this.isVerified = true,
    this.notes = '',
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc().toIso8601String();

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      cnic: map['cnic']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      outstandingBalance: (map['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      activeRentalsCount: (map['activeRentalsCount'] as num?)?.toInt() ?? 0,
      totalBookings: (map['totalBookings'] as num?)?.toInt() ?? 0,
      isVerified: map['isVerified'] as bool? ?? true,
      notes: map['notes']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'cnic': cnic,
      'address': address,
      'outstandingBalance': outstandingBalance,
      'activeRentalsCount': activeRentalsCount,
      'totalBookings': totalBookings,
      'isVerified': isVerified,
      'notes': notes,
      'updatedAt': updatedAt,
    };
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? cnic,
    String? address,
    double? outstandingBalance,
    int? activeRentalsCount,
    int? totalBookings,
    bool? isVerified,
    String? notes,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      address: address ?? this.address,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      activeRentalsCount: activeRentalsCount ?? this.activeRentalsCount,
      totalBookings: totalBookings ?? this.totalBookings,
      isVerified: isVerified ?? this.isVerified,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}
