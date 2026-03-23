class ProductUnitConversion {
  final int? id;
  final int? productId;
  final String unitName;
  final int baseQuantity;
  final double? sellPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductUnitConversion({
    this.id,
    this.productId,
    required this.unitName,
    required this.baseQuantity,
    this.sellPrice,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'unit_name': unitName,
      'base_quantity': baseQuantity,
      'sell_price': sellPrice,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ProductUnitConversion.fromMap(Map<String, dynamic> map) {
    return ProductUnitConversion(
      id: map['id'] as int?,
      productId: map['product_id'] as int?,
      unitName: (map['unit_name'] ?? '').toString(),
      baseQuantity: (map['base_quantity'] as num?)?.toInt() ?? 0,
      sellPrice: (map['sell_price'] as num?)?.toDouble(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
  }

  ProductUnitConversion copyWith({
    int? id,
    int? productId,
    String? unitName,
    int? baseQuantity,
    double? sellPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductUnitConversion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitName: unitName ?? this.unitName,
      baseQuantity: baseQuantity ?? this.baseQuantity,
      sellPrice: sellPrice ?? this.sellPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
