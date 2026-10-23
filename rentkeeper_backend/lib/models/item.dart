class Item {
  final String id;
  final String name;
  final String category;
  final String barcode;
  final String serialNumber;
  final double dailyRate;
  final double replacementValue;
  final int totalStock;
  final int availableStock;
  final int rentedStock;
  final String condition;
  final String status; // 'available', 'partially_rented', 'rented', 'maintenance', 'overdue'
  final String description;
  final String? imageUrl;
  final String updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.barcode,
    required this.serialNumber,
    required this.dailyRate,
    required this.replacementValue,
    required this.totalStock,
    required this.availableStock,
    required this.rentedStock,
    required this.condition,
    required this.status,
    required this.description,
    this.imageUrl,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc().toIso8601String();

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'general',
      barcode: map['barcode']?.toString() ?? '',
      serialNumber: map['serialNumber']?.toString() ?? '',
      dailyRate: (map['dailyRate'] as num?)?.toDouble() ?? 0.0,
      replacementValue: (map['replacementValue'] as num?)?.toDouble() ?? 0.0,
      totalStock: (map['totalStock'] as num?)?.toInt() ?? 1,
      availableStock: (map['availableStock'] as num?)?.toInt() ?? 1,
      rentedStock: (map['rentedStock'] as num?)?.toInt() ?? 0,
      condition: map['condition']?.toString() ?? 'good',
      status: map['status']?.toString() ?? 'available',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'barcode': barcode,
      'serialNumber': serialNumber,
      'dailyRate': dailyRate,
      'replacementValue': replacementValue,
      'totalStock': totalStock,
      'availableStock': availableStock,
      'rentedStock': rentedStock,
      'condition': condition,
      'status': status,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'updatedAt': updatedAt,
    };
  }

  Item copyWith({
    String? name,
    String? category,
    String? barcode,
    String? serialNumber,
    double? dailyRate,
    double? replacementValue,
    int? totalStock,
    int? availableStock,
    int? rentedStock,
    String? condition,
    String? status,
    String? description,
    String? imageUrl,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      serialNumber: serialNumber ?? this.serialNumber,
      dailyRate: dailyRate ?? this.dailyRate,
      replacementValue: replacementValue ?? this.replacementValue,
      totalStock: totalStock ?? this.totalStock,
      availableStock: availableStock ?? this.availableStock,
      rentedStock: rentedStock ?? this.rentedStock,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }
}
