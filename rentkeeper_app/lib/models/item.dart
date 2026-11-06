class RentalItem {
  final String id;
  String name;
  String category;
  String barcode;
  String serialNumber;
  double dailyRate;
  double replacementValue;
  int totalStock;
  int availableStock;
  int rentedStock;
  String condition; // 'mint', 'good', 'fair', 'damaged'
  String status; // 'available', 'partially_rented', 'rented_out', 'maintenance'
  String description;
  String imageUrl;
  DateTime updatedAt;

  RentalItem({
    required this.id,
    required this.name,
    required this.category,
    this.barcode = '',
    this.serialNumber = '',
    required this.dailyRate,
    required this.replacementValue,
    required this.totalStock,
    required this.availableStock,
    this.rentedStock = 0,
    this.condition = 'mint',
    this.status = 'available',
    this.description = '',
    this.imageUrl = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
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
        'imageUrl': imageUrl,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    final total = (json['totalStock'] as num?)?.toInt() ?? 1;
    final available = (json['availableStock'] as num?)?.toInt() ?? total;
    final rented = (json['rentedStock'] as num?)?.toInt() ?? (total - available);

    return RentalItem(
      id: json['id'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? '',
      category: json['category'] ?? 'general',
      barcode: json['barcode'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      replacementValue: (json['replacementValue'] as num?)?.toDouble() ?? 0.0,
      totalStock: total,
      availableStock: available,
      rentedStock: rented,
      condition: json['condition'] ?? 'good',
      status: json['status'] ?? (available > 0 ? 'available' : 'rented_out'),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
