class ProductModel {
  int? id;
  String name;
  String category;
  int? categoryId;
  double purchasePrice;
  double sellingPrice;
  int quantity;
  String baseUnit;
  double costPerUnit;
  double pricePerUnit;
  String? image;
  DateTime createdAt;
  DateTime updatedAt;

  ProductModel({
    this.id,
    required this.name,
    required this.category,
    this.categoryId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    this.baseUnit = 'pcs',
    double? costPerUnit,
    double? pricePerUnit,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  }) : costPerUnit = costPerUnit ?? purchasePrice,
       pricePerUnit = pricePerUnit ?? sellingPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'category_id': categoryId,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'base_unit': baseUnit,
      'cost_per_unit': costPerUnit,
      'price_per_unit': pricePerUnit,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      categoryId: map['category_id'] as int?,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      baseUnit: (map['base_unit'] ?? 'pcs').toString(),
      costPerUnit: (map['cost_per_unit'] as num?)?.toDouble() ??
          (map['purchase_price'] as num?)?.toDouble() ??
          0.0,
      pricePerUnit: (map['price_per_unit'] as num?)?.toDouble() ??
          (map['selling_price'] as num?)?.toDouble() ??
          0.0,
      image: map['image'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get stockDisplay => '$quantity $baseUnit';
}
