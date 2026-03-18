class ProductSellingOption {
  final int? id;
  final int? productId;
  final String label;
  final String mode;
  final String? unitName;
  final int? baseQuantity;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductSellingOption({
    this.id,
    this.productId,
    required this.label,
    required this.mode,
    this.unitName,
    this.baseQuantity,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'label': label,
      'mode': mode,
      'unit_name': unitName,
      'base_quantity': baseQuantity,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ProductSellingOption.fromMap(Map<String, dynamic> map) {
    return ProductSellingOption(
      id: map['id'] as int?,
      productId: map['product_id'] as int?,
      label: (map['label'] ?? '').toString(),
      mode: (map['mode'] ?? '').toString(),
      unitName: map['unit_name']?.toString(),
      baseQuantity: (map['base_quantity'] as num?)?.toInt(),
      price: (map['price'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
  }

  ProductSellingOption copyWith({
    int? id,
    int? productId,
    String? label,
    String? mode,
    String? unitName,
    int? baseQuantity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductSellingOption(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      label: label ?? this.label,
      mode: mode ?? this.mode,
      unitName: unitName ?? this.unitName,
      baseQuantity: baseQuantity ?? this.baseQuantity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
